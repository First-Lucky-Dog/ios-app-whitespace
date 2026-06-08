//
//  FocusShellViews.swift
//  whitespace
//
//  用途：承载应用壳层、启动页、专注首页和辅助说明页等顶层页面。
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct MainShell<Content: View>: View {
    @ObservedObject var appState: FocusAppState
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !appState.isFocusing {
                AppTabBar(selectedTab: $appState.selectedTab) { tab in
                    appState.show(tab: tab)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct OnboardingView: View {
    let onEnter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("NO SCROLL")
                    .font(.focusCaption)
                    .foregroundStyle(FocusPalette.textSecondary)
                Spacer()
                Text("FOCUS SYSTEM")
                    .font(.focusCaption)
                    .foregroundStyle(FocusPalette.textSecondary)
            }
            .padding(.top, 22)

            Spacer()

            Rectangle()
                .fill(FocusPalette.accent)
                .frame(width: 86, height: 14)
                .padding(.bottom, 20)

            Text("不刷了")
                .font(.system(size: 72, weight: .ultraLight))
                .tracking(-2)
                .foregroundStyle(FocusPalette.textPrimary)

            Text("少刷一点，把时间拿回来")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(FocusPalette.textSecondary)
                .padding(.top, 12)
                .padding(.bottom, 52)

            PrimaryButton(title: "进入空间", action: onEnter)

            Spacer()
        }
        .padding(.horizontal, FocusLayout.pageHorizontalPadding)
        .background {
            SwissGridBackground(spacing: 28)
                .opacity(0.82)
        }
    }
}

struct FocusHomeView: View {
    let isFocusing: Bool
    let allowedSelection: FamilyActivitySelection
    let pendingCount: Int
    let elapsedText: String
    let clockText: String
    let onStart: () -> Void
    let onExitRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isFocusing {
                HStack {
                    HStack(spacing: 8) {
                        FocusBrandBadge()
                        Text("不刷了")
                            .font(.focusCaption)
                            .foregroundStyle(FocusPalette.textSecondary)
                    }
                    Spacer()
                    Text(Date().focusClockText)
                        .font(.focusCaption)
                        .monospacedDigit()
                        .foregroundStyle(FocusPalette.textSecondary)
                }
                .padding(.horizontal, FocusLayout.pageHorizontalPadding)
                .padding(.top, 22)
            }

            Spacer()
            VStack(spacing: 0) {
                ZenCircle(
                    isActive: isFocusing,
                    elapsedText: elapsedText,
                    clockText: clockText,
                    action: isFocusing ? onExitRequest : onStart
                )

                if isFocusing {
                    AllowedActivityStrip(selection: allowedSelection)
                        .padding(.top, 32)
                } else {
                    Text(pendingCount > 0 ? "今日还有 \(pendingCount) 项待办任务" : "今日任务已全部完成")
                        .font(.focusCaption)
                        .foregroundStyle(FocusPalette.textSecondary)
                        .padding(.top, 18)
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if !isFocusing {
                SwissGridBackground(spacing: 32)
            }
        }
    }
}

private struct FocusBrandBadge: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(FocusPalette.accent)
                .frame(width: 16, height: 16)

            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(FocusPalette.accentOn)
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

struct AllowedActivityStrip: View {
    let selection: FamilyActivitySelection

    private var applicationTokens: [ApplicationToken] {
        Array(selection.applicationTokens)
    }

    private var webDomainTokens: [WebDomainToken] {
        Array(selection.webDomainTokens)
    }

    private var visibleItemCount: Int {
        applicationTokens.count + webDomainTokens.count
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(applicationTokens, id: \.self) { token in
                        AllowedActivityIcon {
                            Label(token)
                                .labelStyle(.iconOnly)
                        }
                    }

                    ForEach(webDomainTokens, id: \.self) { token in
                        AllowedActivityIcon {
                            Label(token)
                                .labelStyle(.iconOnly)
                        }
                    }

                    if applicationTokens.isEmpty, webDomainTokens.isEmpty {
                        AllowedActivityIcon {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                // 单个或少量可访问 App 也要保持视觉居中，不从左侧起排。
                .frame(minWidth: proxy.size.width, alignment: .center)
                .padding(.horizontal, visibleItemCount > 3 ? 8 : 0)
            }
        }
        .frame(maxWidth: 360)
        .frame(height: 116)
    }
}

struct AllowedActivityIcon<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            content
                .font(.system(size: 40, weight: .semibold))
                .scaleEffect(2.45)
                .frame(width: 46, height: 46)
        }
        .frame(width: 112, height: 112, alignment: .center)
    }
}

struct PermissionsView: View {
    let screenTimeAuthorized: Bool
    let whitelistConfigured: Bool
    let screenTimeReadyForPermissionCompletion: Bool
    let notificationAuthorized: Bool
    let screenTimeSummary: String
    let whitelistSummary: String
    let screenTimeErrorMessage: String?
    let onRequestScreenTime: () -> Void
    let onConfigureWhitelist: () -> Void
    let onRequestNotifications: () -> Void
    let onComplete: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageHeader(eyebrow: "首次启用", title: "申请系统权限")

                Text("限制其他娱乐软件运行，需要获得您的授权。")
                    .font(.system(size: 16))
                    .foregroundStyle(FocusPalette.textSecondary)

                IOSListGroup {
                    IOSListRow {
                        ListLabel(title: "屏幕使用时间", subtitle: screenTimeSummary, titleWeight: .medium)
                    } trailing: {
                        SmallPillButton(
                            title: screenTimeAuthorized ? "已授权" : "授权",
                            isActive: screenTimeAuthorized,
                            isEnabled: !screenTimeAuthorized,
                            action: onRequestScreenTime
                        )
                    }
                    DividerLine()
                    IOSListRow {
                        ListLabel(title: "允许使用的 App/网站", subtitle: whitelistSummary, titleWeight: .medium)
                    } trailing: {
                        SmallPillButton(
                            title: whitelistConfigured ? "已选择" : "选择",
                            isActive: whitelistConfigured,
                            isEnabled: screenTimeAuthorized,
                            action: onConfigureWhitelist
                        )
                    }
                    DividerLine()
                    IOSListRow {
                        ListLabel(title: "本地通知（可选）", subtitle: "用于专注结束提醒，可稍后在设置中开启", titleWeight: .medium)
                    } trailing: {
                        SmallPillButton(title: notificationAuthorized ? "已授权" : "允许", isActive: notificationAuthorized, action: onRequestNotifications)
                    }
                }

                if let screenTimeErrorMessage {
                    Text(screenTimeErrorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(FocusPalette.danger)
                        .lineSpacing(3)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, FocusLayout.pageHorizontalPadding)
            .padding(.top, FocusLayout.pageTopPadding)
            .padding(.bottom, 112)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                PrimaryButton(title: "完成并开启", isEnabled: screenTimeReadyForPermissionCompletion, action: onComplete)
                GhostButton(title: "返回", action: onBack)
            }
            .padding(.horizontal, FocusLayout.pageHorizontalPadding)
            .padding(.top, FocusLayout.bottomActionTopPadding)
            .padding(.bottom, FocusLayout.bottomActionBottomPadding)
            .background(FocusPalette.background)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(FocusPalette.borderSubtle)
                    .frame(height: 1)
            }
        }
    }
}

struct RecoveryView: View {
    let onSync: () -> Void
    let onForceUnlock: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageHeader(eyebrow: "应急工具", title: "异常恢复")
            Text("用于处理偶发性的系统锁屏策略残留。")
                .font(.system(size: 15))
                .foregroundStyle(FocusPalette.textSecondary)
            SecondaryButton(title: "同步锁状态", action: onSync)
            SecondaryButton(title: "强制解除屏幕锁定", tint: FocusPalette.danger, action: onForceUnlock)
            GhostButton(title: "返回设置", action: onBack)
            Spacer()
        }
        .padding(.horizontal, FocusLayout.pageHorizontalPadding)
        .padding(.top, FocusLayout.pageTopPadding)
    }
}

struct PrivacyView: View {
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageHeader(eyebrow: "DATA", title: "隐私说明")
            Text("不刷了始终坚守“零服务器”架构，您的屏幕时间参数、允许列表、待办任务及历史记录等隐私均仅在 iPhone 本地沙盒中留存。")
                .font(.system(size: 14))
                .foregroundStyle(FocusPalette.textSecondary)
                .lineSpacing(5)
                .padding(16)
                .iosCard()
            GhostButton(title: "返回设置", action: onBack)
            Spacer()
        }
        .padding(.horizontal, FocusLayout.pageHorizontalPadding)
        .padding(.top, FocusLayout.pageTopPadding)
    }
}
