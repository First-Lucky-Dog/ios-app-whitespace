//
//  ScreenTimeShieldCenter.swift
//  whitespace
//
//  用途：封装 FamilyControls、ManagedSettings 与 DeviceActivity 的授权、允许列表和屏蔽策略。
//

import DeviceActivity
import FamilyControls
import Combine
import Foundation
import ManagedSettings

@MainActor
final class ScreenTimeShieldCenter: ObservableObject {
    @Published private(set) var authorizationStatus: AuthorizationStatus
    @Published private(set) var lastErrorMessage: String?
    @Published var allowedSelection: FamilyActivitySelection {
        didSet { persistAllowedSelection() }
    }
    @Published var blockedSelection: FamilyActivitySelection {
        didSet { persistBlockedSelection() }
    }

    private let defaults: UserDefaults
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("whitespace.focus.store"))
    private let activityCenter = DeviceActivityCenter()
    private let focusActivityName = DeviceActivityName("whitespace.focus.session")

    private enum Keys {
        static let allowedSelection = "focus.allowedActivitySelection"
        static let blockedSelection = "focus.blockedActivitySelection"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        allowedSelection = Self.loadSelection(from: defaults, key: Keys.allowedSelection)
        blockedSelection = Self.loadSelection(from: defaults, key: Keys.blockedSelection)
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .approved, .approvedWithDataAccess:
            true
        case .notDetermined, .denied:
            false
        @unknown default:
            false
        }
    }

    var hasAllowedActivities: Bool {
        !allowedSelection.applicationTokens.isEmpty || !allowedSelection.webDomainTokens.isEmpty
    }

    var hasBlockedActivities: Bool {
        !blockedSelection.applicationTokens.isEmpty || !blockedSelection.webDomainTokens.isEmpty
    }

    var isReadyForPermissionCompletion: Bool {
        isAuthorized && hasAllowedActivities
    }

    var isReadyForFocus: Bool {
        isReadyForPermissionCompletion && hasBlockedActivities
    }

    var allowedSelectionSummary: String {
        selectionSummary(
            selection: allowedSelection,
            emptyText: Self.emptyAllowedSelectionHint,
            configuredPrefix: "已允许"
        )
    }

    var blockedSelectionSummary: String {
        selectionSummary(
            selection: blockedSelection,
            emptyText: Self.emptyBlockedSelectionHint,
            configuredPrefix: "已强制屏蔽"
        )
    }

    var authorizationSummary: String {
        if isReadyForFocus {
            return "已授权并配置允许列表与强制屏蔽列表"
        }
        if !isAuthorized {
            return "需要系统授权"
        }
        if !hasAllowedActivities {
            return allowedSelectionSummary
        }
        return "已授权并配置允许列表"
    }

    private func selectionSummary(
        selection: FamilyActivitySelection,
        emptyText: String,
        configuredPrefix: String
    ) -> String {
        let appCount = selection.applicationTokens.count
        let websiteCount = selection.webDomainTokens.count

        if appCount == 0, websiteCount == 0 {
            return emptyText
        }

        var parts: [String] = []
        if appCount > 0 {
            parts.append("\(appCount) 个 App")
        }
        if websiteCount > 0 {
            parts.append("\(websiteCount) 个网站")
        }
        return configuredPrefix + " " + parts.joined(separator: "、")
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshAuthorizationStatus()
            lastErrorMessage = nil
            return isAuthorized
        } catch {
            refreshAuthorizationStatus()
            lastErrorMessage = "屏幕使用时间授权失败：\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func applyFocusShield() -> Bool {
        refreshAuthorizationStatus()

        guard isAuthorized else {
            lastErrorMessage = "请先授予屏幕使用时间权限。"
            return false
        }
        guard hasAllowedActivities else {
            lastErrorMessage = "请先选择专注期间允许使用的 App。"
            return false
        }

        var effectiveAllowedApps = allowedSelection.applicationTokens
        effectiveAllowedApps.subtract(blockedSelection.applicationTokens)
        var effectiveAllowedWebDomains = allowedSelection.webDomainTokens
        effectiveAllowedWebDomains.subtract(blockedSelection.webDomainTokens)

        // 双层防护：先用允许列表兜底屏蔽全部分类，再对重点 App/网站做显式强制屏蔽。
        store.shield.applications = blockedSelection.applicationTokens
        store.shield.webDomains = blockedSelection.webDomainTokens
        store.shield.applicationCategories = .all(except: effectiveAllowedApps)
        store.shield.webDomainCategories = .all(except: effectiveAllowedWebDomains)
        startMonitoringCurrentFocusInterval()
        lastErrorMessage = nil
        return true
    }

    func clearFocusShield() {
        activityCenter.stopMonitoring([focusActivityName])
        store.clearAllSettings()
        lastErrorMessage = nil
    }

    func resetLocalConfiguration() {
        clearFocusShield()
        allowedSelection = FamilyActivitySelection(includeEntireCategory: false)
        blockedSelection = FamilyActivitySelection(includeEntireCategory: false)
        defaults.removeObject(forKey: Keys.allowedSelection)
        defaults.removeObject(forKey: Keys.blockedSelection)
        refreshAuthorizationStatus()
    }

    private func startMonitoringCurrentFocusInterval() {
        let calendar = Calendar.current
        let now = Date()
        let end = now.addingTimeInterval(12 * 60 * 60)
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: now),
            intervalEnd: calendar.dateComponents(components, from: end),
            repeats: false
        )

        do {
            try activityCenter.startMonitoring(focusActivityName, during: schedule)
        } catch {
            lastErrorMessage = "DeviceActivity 监控启动失败：\(error.localizedDescription)"
        }
    }

    private func persistAllowedSelection() {
        if let data = try? JSONEncoder().encode(allowedSelection) {
            defaults.set(data, forKey: Keys.allowedSelection)
        }
    }

    private func persistBlockedSelection() {
        if let data = try? JSONEncoder().encode(blockedSelection) {
            defaults.set(data, forKey: Keys.blockedSelection)
        }
    }

    private static func loadSelection(from defaults: UserDefaults, key: String) -> FamilyActivitySelection {
        guard
            let data = defaults.data(forKey: key),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection(includeEntireCategory: false)
        }

        return selection
    }

    private static var emptyAllowedSelectionHint: String {
        "未选择，可自由添加 App"
    }

    private static var emptyBlockedSelectionHint: String {
        "未选择，建议添加抖音、TikTok、小红书等"
    }
}
