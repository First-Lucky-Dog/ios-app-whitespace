//
//  FocusLiveActivityCenter.swift
//  whitespace
//
//  用途：集中管理专注 Live Activity 的启动、恢复和结束。
//

import ActivityKit
import Combine
import Foundation

@MainActor
final class FocusLiveActivityCenter: ObservableObject {
    @Published private(set) var activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    @Published private(set) var lastErrorMessage: String?

    private var currentActivityID: Activity<FocusLiveActivityAttributes>.ID?

    func refreshAuthorization() {
        activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(target: String, startedAt: Date) async {
        refreshAuthorization()
        guard activitiesEnabled else {
            lastErrorMessage = "系统未开启实时活动。"
            return
        }

        await endAllActiveActivities(dismissalPolicy: .immediate)

        let attributes = FocusLiveActivityAttributes(
            focusID: UUID().uuidString,
            appURLString: FocusLiveActivityAttributes.appURLString
        )
        let content = activityContent(target: target, startedAt: startedAt, relevanceScore: 1)

        do {
            let activity = try Activity<FocusLiveActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivityID = activity.id
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "无法显示实时专注状态。"
        }
    }

    func resumeIfNeeded(target: String, startedAt: Date) async {
        refreshAuthorization()
        guard activitiesEnabled else { return }

        if let activity = Activity<FocusLiveActivityAttributes>.activities.first {
            currentActivityID = activity.id
            await activity.update(activityContent(target: target, startedAt: startedAt, relevanceScore: 1))
        } else {
            await start(target: target, startedAt: startedAt)
        }
    }

    func end(target: String, startedAt: Date?) async {
        let content: ActivityContent<FocusLiveActivityAttributes.ContentState>?
        if let startedAt {
            content = activityContent(target: target, startedAt: startedAt, isFinished: true, relevanceScore: 0)
        } else {
            content = nil
        }

        await endAllActiveActivities(content: content, dismissalPolicy: .immediate)
        currentActivityID = nil
        lastErrorMessage = nil
    }

    private func activityContent(
        target: String,
        startedAt: Date,
        isFinished: Bool = false,
        relevanceScore: Double
    ) -> ActivityContent<FocusLiveActivityAttributes.ContentState> {
        let state = FocusLiveActivityAttributes.ContentState(
            startedAt: startedAt,
            target: target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未设特定目标" : target,
            isFinished: isFinished
        )
        return ActivityContent(
            state: state,
            staleDate: isFinished ? nil : startedAt.addingTimeInterval(8 * 60 * 60),
            relevanceScore: relevanceScore
        )
    }

    private func endAllActiveActivities(
        content: ActivityContent<FocusLiveActivityAttributes.ContentState>? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        for activity in Activity<FocusLiveActivityAttributes>.activities {
            await activity.end(content, dismissalPolicy: dismissalPolicy)
        }
    }
}
