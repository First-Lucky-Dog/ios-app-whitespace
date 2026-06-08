//
//  FocusAppState.swift
//  whitespace
//
//  用途：集中管理页面路由、专注计时、弹窗状态和轻量偏好。
//

import Foundation
import Combine

enum AppRoute: Equatable {
    case onboarding
    case main(AppTab)
    case permissions
    case recovery
    case privacy
}

enum AppTab: Hashable {
    case focus
    case todos
    case settings
}

enum ActiveDialog: Identifiable {
    case goal
    case exit
    case reset

    var id: String {
        switch self {
        case .goal: "goal"
        case .exit: "exit"
        case .reset: "reset"
        }
    }
}

struct FocusSummary: Identifiable {
    let id = UUID()
    let durationSeconds: Int
    let target: String
}

@MainActor
final class FocusAppState: ObservableObject {
    @Published var route: AppRoute
    @Published var selectedTab: AppTab = .focus
    @Published var activeDialog: ActiveDialog?
    @Published var reportSummary: FocusSummary?
    @Published var isFocusing = false {
        didSet { UserDefaults.standard.set(isFocusing, forKey: Keys.isFocusing) }
    }
    @Published var focusStartedAt: Date? {
        didSet {
            if let focusStartedAt {
                UserDefaults.standard.set(focusStartedAt, forKey: Keys.focusStartedAt)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.focusStartedAt)
            }
        }
    }
    @Published var elapsedSeconds = 0
    @Published var currentFocusTarget = "" {
        didSet { UserDefaults.standard.set(currentFocusTarget, forKey: Keys.currentFocusTarget) }
    }
    @Published var screenTimeAuthorized: Bool {
        didSet { UserDefaults.standard.set(screenTimeAuthorized, forKey: Keys.screenTimeAuthorized) }
    }
    @Published var notificationAuthorized: Bool {
        didSet { UserDefaults.standard.set(notificationAuthorized, forKey: Keys.notificationAuthorized) }
    }
    @Published var skipGoalPrompt: Bool {
        didSet { UserDefaults.standard.set(skipGoalPrompt, forKey: Keys.skipGoalPrompt) }
    }
    @Published var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    private enum Keys {
        static let screenTimeAuthorized = "focus.screenTimeAuthorized"
        static let notificationAuthorized = "focus.notificationAuthorized"
        static let skipGoalPrompt = "focus.skipGoalPrompt"
        static let hasSeenOnboarding = "focus.hasSeenOnboarding"
        static let isFocusing = "focus.isFocusing"
        static let focusStartedAt = "focus.startedAt"
        static let currentFocusTarget = "focus.currentTarget"
    }

    init() {
        let defaults = UserDefaults.standard
        let savedHasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        let savedFocusStartedAt = defaults.object(forKey: Keys.focusStartedAt) as? Date
        let shouldRestoreFocus = defaults.bool(forKey: Keys.isFocusing) && savedFocusStartedAt != nil

        screenTimeAuthorized = defaults.bool(forKey: Keys.screenTimeAuthorized)
        notificationAuthorized = defaults.bool(forKey: Keys.notificationAuthorized)
        skipGoalPrompt = defaults.bool(forKey: Keys.skipGoalPrompt)
        hasSeenOnboarding = savedHasSeenOnboarding
        route = savedHasSeenOnboarding ? .main(.focus) : .onboarding

        if shouldRestoreFocus, let savedFocusStartedAt {
            isFocusing = true
            focusStartedAt = savedFocusStartedAt
            currentFocusTarget = defaults.string(forKey: Keys.currentFocusTarget) ?? "未设特定目标"
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(savedFocusStartedAt)))
            selectedTab = .focus
        } else {
            isFocusing = false
            focusStartedAt = nil
            currentFocusTarget = ""
        }
    }

    var hasRequiredPermissions: Bool {
        screenTimeAuthorized && notificationAuthorized
    }

    func enterApp() {
        hasSeenOnboarding = true
        show(tab: .focus)
    }

    func show(tab: AppTab) {
        selectedTab = tab
        route = .main(tab)
    }

    func requestStartFocus() {
        guard hasRequiredPermissions else {
            route = .permissions
            return
        }

        if skipGoalPrompt {
            beginFocus(target: "未设特定目标")
        } else {
            activeDialog = .goal
        }
    }

    func beginFocus(target: String, startedAt: Date = .now) {
        currentFocusTarget = target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未设特定目标" : target
        selectedTab = .focus
        route = .main(.focus)
        focusStartedAt = startedAt
        elapsedSeconds = 0
        isFocusing = true
        activeDialog = nil
    }

    func tick(now: Date = .now) {
        guard let focusStartedAt, isFocusing else { return }
        elapsedSeconds = max(0, Int(now.timeIntervalSince(focusStartedAt)))
    }

    func requestExitFocus() {
        activeDialog = .exit
    }

    func finishFocus() -> FocusRecord? {
        guard isFocusing, let startedAt = focusStartedAt else { return nil }
        tick()
        let duration = max(1, elapsedSeconds)
        let target = currentFocusTarget.isEmpty ? "未设特定目标" : currentFocusTarget
        let record = FocusRecord(target: target, startedAt: startedAt, endedAt: .now, durationSeconds: duration)
        isFocusing = false
        focusStartedAt = nil
        elapsedSeconds = 0
        activeDialog = nil
        reportSummary = FocusSummary(durationSeconds: duration, target: target)
        return record
    }

    func resetTransientState() {
        isFocusing = false
        focusStartedAt = nil
        elapsedSeconds = 0
        currentFocusTarget = ""
        activeDialog = nil
        reportSummary = nil
    }

    func resetPreferences() {
        resetTransientState()
        screenTimeAuthorized = false
        notificationAuthorized = false
        skipGoalPrompt = false
        hasSeenOnboarding = false
        route = .onboarding
        selectedTab = .focus
    }
}

extension Int {
    var focusDurationText: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

extension Date {
    var focusClockText: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: self)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    var focusHistoryDateText: String {
        let components = Calendar.current.dateComponents([.month, .day], from: self)
        return "\(components.month ?? 1)月\(components.day ?? 1)日"
    }
}
