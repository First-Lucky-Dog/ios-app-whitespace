//
//  ContentView.swift
//  whitespace
//
//  用途：应用根视图，负责路由切换、SwiftData 读写和页面间事件协调。
//

import SwiftUI
import SwiftData
import Combine
import FamilyControls
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .forward) private var todos: [TodoItem]
    @Query(sort: \FocusRecord.startedAt, order: .reverse) private var records: [FocusRecord]
    @StateObject private var appState = FocusAppState()
    @StateObject private var screenTimeCenter = ScreenTimeShieldCenter()
    @StateObject private var liveActivityCenter = FocusLiveActivityCenter()
    @State private var newTodoTitle = ""
    @State private var goalTitle = ""
    @State private var goalSkipFuture = false
    @State private var isShowingAllowedActivityPicker = false
    @State private var isShowingBlockedActivityPicker = false

    // 计时显示以开始时间为准重新计算，避免 App 进入后台后只靠自增计时产生漂移。
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            (appState.isFocusing ? FocusPalette.ink : FocusPalette.background)
                .ignoresSafeArea()

            routeView

            if let activeDialog = appState.activeDialog {
                dialogOverlay(for: activeDialog)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: appState.isFocusing)
        .animation(.easeInOut(duration: 0.2), value: appState.activeDialog?.id)
        .sheet(item: $appState.reportSummary) { summary in
            FocusReportSheet(summary: summary) {
                appState.reportSummary = nil
                appState.show(tab: .focus)
            }
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.visible)
        }
        .familyActivityPicker(
            headerText: "选择专注时允许使用的 App",
            footerText: "可自由选择专注期间仍可使用的 App。",
            isPresented: $isShowingAllowedActivityPicker,
            selection: $screenTimeCenter.allowedSelection
        )
        .familyActivityPicker(
            headerText: "选择专注时要屏蔽的 App/网站",
            footerText: "这是专注前的防护名单，不是系统权限。建议添加抖音、TikTok、小红书等容易漏网的 App/网站；强制屏蔽优先于允许列表。",
            isPresented: $isShowingBlockedActivityPicker,
            selection: $screenTimeCenter.blockedSelection
        )
        .onReceive(ticker) { now in
            appState.tick(now: now)
        }
        .onAppear {
            refreshSystemPermissionState()
            refreshLiveActivityState()
        }
        .onOpenURL(perform: handleOpenURL)
        .onChange(of: screenTimeCenter.authorizationStatus) { _, _ in
            syncScreenTimeReadiness()
        }
        .onChange(of: screenTimeCenter.allowedSelection) { _, _ in
            syncScreenTimeReadiness()
        }
        .onChange(of: screenTimeCenter.blockedSelection) { _, _ in
            syncScreenTimeReadiness()
        }
    }

    @ViewBuilder
    private var routeView: some View {
        switch appState.route {
        case .onboarding:
            OnboardingView {
                appState.enterApp()
            }
        case .permissions:
            PermissionsView(
                screenTimeAuthorized: screenTimeCenter.isAuthorized,
                whitelistConfigured: screenTimeCenter.hasAllowedActivities,
                screenTimeReadyForPermissionCompletion: screenTimeCenter.isReadyForPermissionCompletion,
                notificationAuthorized: appState.notificationAuthorized,
                screenTimeSummary: screenTimeCenter.authorizationSummary,
                whitelistSummary: screenTimeCenter.allowedSelectionSummary,
                screenTimeErrorMessage: screenTimeCenter.lastErrorMessage,
                onRequestScreenTime: requestScreenTimeAuthorization,
                onConfigureWhitelist: { isShowingAllowedActivityPicker = true },
                onRequestNotifications: requestNotificationAuthorization,
                onComplete: completePermissionsAndBeginFocus,
                onBack: { appState.show(tab: .focus) }
            )
        case .recovery:
            RecoveryView(
                onSync: {
                    refreshSystemPermissionState()
                    appState.show(tab: .settings)
                },
                onForceUnlock: {
                    screenTimeCenter.clearFocusShield()
                    endLiveActivity()
                    appState.resetTransientState()
                    appState.show(tab: .settings)
                },
                onBack: { appState.show(tab: .settings) }
            )
        case .privacy:
            PrivacyView {
                appState.show(tab: .settings)
            }
        case .main:
            MainShell(appState: appState) {
                mainTabContent
            }
        }
    }

    @ViewBuilder
    private var mainTabContent: some View {
        switch appState.selectedTab {
        case .focus:
            FocusHomeView(
                isFocusing: appState.isFocusing,
                allowedSelection: screenTimeCenter.allowedSelection,
                pendingCount: todos.filter { !$0.isDone }.count,
                elapsedText: appState.elapsedSeconds.focusDurationText,
                clockText: Date().focusClockText,
                onStart: startFocusFlow,
                onExitRequest: { appState.requestExitFocus() }
            )
        case .todos:
            TodoListView(
                todos: todos,
                newTodoTitle: $newTodoTitle,
                onAdd: addTodo,
                onToggle: toggleTodo
            )
        case .settings:
            SettingsView(
                records: records,
                skipGoalPrompt: $appState.skipGoalPrompt,
                screenTimeSummary: screenTimeCenter.authorizationSummary,
                blocklistSummary: screenTimeCenter.blockedSelectionSummary,
                onConfigureWhitelist: { isShowingAllowedActivityPicker = true },
                onConfigureBlocklist: { isShowingBlockedActivityPicker = true },
                onRecovery: { appState.route = .recovery },
                onPrivacy: { appState.route = .privacy },
                onReset: { appState.activeDialog = .reset },
                onBackHome: { appState.show(tab: .focus) }
            )
        }
    }

    private func dialogOverlay(for dialog: ActiveDialog) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            switch dialog {
            case .goal:
                GoalPromptView(
                    target: $goalTitle,
                    skipFuture: $goalSkipFuture,
                    onSkip: beginFocusFromPromptWithoutGoal,
                    onStart: beginFocusFromPrompt
                )
            case .exit:
                ExitFocusPromptView(
                    onContinue: { appState.activeDialog = nil },
                    onExit: finishFocus
                )
            case .reset:
                ResetPromptView(
                    onCancel: { appState.activeDialog = nil },
                    onConfirm: resetAllData
                )
            }
        }
        .transition(.opacity)
    }

    private func startFocusFlow() {
        syncScreenTimeReadiness()
        guard appState.hasRequiredPermissions else {
            appState.route = .permissions
            return
        }

        continueStartFocusFlow()
    }

    private func completePermissionsAndBeginFocus() {
        syncScreenTimeReadiness()
        guard appState.hasRequiredPermissions else {
            appState.route = .permissions
            return
        }

        beginFocus(target: "未设特定目标")
    }

    private func continueStartFocusFlow() {
        if appState.skipGoalPrompt {
            beginFocus(target: "未设特定目标")
        } else {
            goalTitle = ""
            goalSkipFuture = false
            appState.activeDialog = .goal
        }
    }

    private func beginFocusFromPromptWithoutGoal() {
        if goalSkipFuture {
            appState.skipGoalPrompt = true
        }
        beginFocus(target: "未设特定目标")
    }

    private func beginFocusFromPrompt() {
        let trimmed = goalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if goalSkipFuture {
            appState.skipGoalPrompt = true
        }
        let target = trimmed.isEmpty ? "未设特定目标" : trimmed
        beginFocus(target: target) {
            if !trimmed.isEmpty {
                modelContext.insert(TodoItem(title: trimmed))
            }
        }
    }

    private func beginFocus(target: String, afterShieldApplied: (() -> Void)? = nil) {
        guard screenTimeCenter.applyFocusShield() else {
            syncScreenTimeReadiness()
            appState.route = .permissions
            return
        }

        afterShieldApplied?()
        let startedAt = Date()
        appState.beginFocus(target: target, startedAt: startedAt)
        Task {
            await liveActivityCenter.start(target: appState.currentFocusTarget, startedAt: startedAt)
        }
    }

    private func finishFocus() {
        let startedAt = appState.focusStartedAt
        let target = appState.currentFocusTarget
        screenTimeCenter.clearFocusShield()
        guard let record = appState.finishFocus() else { return }
        endLiveActivity(target: target, startedAt: startedAt)
        modelContext.insert(record)
    }

    private func addTodo() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            modelContext.insert(TodoItem(title: trimmed))
            newTodoTitle = ""
        }
    }

    private func toggleTodo(_ todo: TodoItem) {
        withAnimation {
            todo.isDone.toggle()
            todo.completedAt = todo.isDone ? .now : nil
        }
    }

    private func resetAllData() {
        withAnimation {
            todos.forEach { modelContext.delete($0) }
            records.forEach { modelContext.delete($0) }
        }
        screenTimeCenter.resetLocalConfiguration()
        endLiveActivity()
        appState.resetPreferences()
    }

    private func requestScreenTimeAuthorization() {
        Task {
            await screenTimeCenter.requestAuthorization()
            syncScreenTimeReadiness()
        }
    }

    private func requestNotificationAuthorization() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            appState.notificationAuthorized = granted
        }
    }

    private func refreshSystemPermissionState() {
        screenTimeCenter.refreshAuthorizationStatus()
        syncScreenTimeReadiness()
        refreshNotificationAuthorization()
    }

    private func refreshLiveActivityState() {
        liveActivityCenter.refreshAuthorization()
        guard appState.isFocusing, let startedAt = appState.focusStartedAt else { return }
        Task {
            await liveActivityCenter.resumeIfNeeded(target: appState.currentFocusTarget, startedAt: startedAt)
        }
    }

    private func syncScreenTimeReadiness() {
        appState.screenTimeAuthorized = screenTimeCenter.isReadyForPermissionCompletion
    }

    private func refreshNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                appState.notificationAuthorized = settings.isFocusNotificationAllowed
            }
        }
    }

    private func handleOpenURL(_ url: URL) {
        guard url.scheme == "whitespace" else { return }
        appState.show(tab: .focus)
    }

    private func endLiveActivity(target: String = "", startedAt: Date? = nil) {
        Task {
            await liveActivityCenter.end(target: target, startedAt: startedAt)
        }
    }
}

private extension UNNotificationSettings {
    var isFocusNotificationAllowed: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            true
        case .denied, .notDetermined:
            false
        @unknown default:
            false
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TodoItem.self, FocusRecord.self], inMemory: true)
}
