//
//  FocusComponents.swift
//  whitespace
//
//  用途：封装可复用的 SwiftUI 基础控件，如按钮、列表行、专注圆和底部导航。
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(FocusPalette.accentOn.opacity(isEnabled ? 1 : 0.45))
                .background(isEnabled ? FocusPalette.accent : FocusPalette.borderSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        }
        .disabled(!isEnabled)
        .pressableScale()
    }
}

struct SecondaryButton: View {
    let title: String
    var tint: Color = FocusPalette.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(tint)
                .background(FocusPalette.paper)
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(tint == FocusPalette.textPrimary ? FocusPalette.border : tint, lineWidth: 1)
                }
        }
        .pressableScale()
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(FocusPalette.textPrimary)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(FocusPalette.accent)
                        .frame(height: 2)
                }
        }
        .buttonStyle(.plain)
    }
}

struct SmallPillButton: View {
    let title: String
    var isActive = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(isActive ? FocusPalette.accentOn : FocusPalette.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(isActive ? FocusPalette.accent : FocusPalette.paper)
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .stroke(isActive ? FocusPalette.accent : FocusPalette.border, lineWidth: 1)
                }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled || isActive ? 1 : 0.55)
        .pressableScale()
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(FocusPalette.accent)
                    .frame(width: 28, height: 8)
                Text(eyebrow.uppercased())
                    .font(.focusCaption)
                    .foregroundStyle(FocusPalette.textSecondary)
            }
            Text(title)
                .font(.focusTitle)
                .tracking(-0.8)
                .foregroundStyle(FocusPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(.focusSection)
                .foregroundStyle(FocusPalette.textSecondary)
            Rectangle()
                .fill(FocusPalette.borderSubtle)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }
}

struct IOSListGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .iosCard()
    }
}

struct IOSListRow<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            leading
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, FocusLayout.listRowHorizontalPadding)
        .padding(.vertical, 7)
        .frame(minHeight: 62)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(FocusPalette.border)
            .frame(height: 1)
            .padding(.leading, FocusLayout.listRowHorizontalPadding)
    }
}

struct ListLabel: View {
    let title: String
    var subtitle: String?
    var titleColor: Color = FocusPalette.textPrimary
    var titleWeight: Font.Weight = .regular

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: titleWeight))
                .foregroundStyle(titleColor)
            if let subtitle {
                Text(subtitle)
                    .font(.focusCaption)
                    .foregroundStyle(FocusPalette.textSecondary)
                    .lineSpacing(3)
            }
        }
    }
}

struct ZenCircle: View {
    let isActive: Bool
    let elapsedText: String
    let clockText: String
    let action: () -> Void
    @State private var isBreathing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                SwissGridBackground(spacing: 28, lineColor: isActive ? .white.opacity(0.08) : FocusPalette.gridLine)

                Circle()
                    .fill(isActive ? .white.opacity(0.08) : FocusPalette.accent.opacity(0.18))
                    .scaleEffect(isBreathing ? 1.08 : 0.94)
                    .opacity(isBreathing ? 0.55 : 0.18)

                Rectangle()
                    .fill(isActive ? .white.opacity(0.14) : FocusPalette.accent)
                    .frame(width: 44, height: 8)

                VStack(spacing: isActive ? 8 : 10) {
                    if isActive {
                        Text(elapsedText)
                            .font(.system(size: 54, weight: .ultraLight, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text("CURRENT \(clockText)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.56))
                        Text("点击结束")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.42))
                            .padding(.top, 10)
                    } else {
                        Text("开始专注")
                            .font(.system(size: 28, weight: .light))
                            .tracking(1)
                            .foregroundStyle(FocusPalette.textPrimary)
                        Text("TAP TO LOCK")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(FocusPalette.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .multilineTextAlignment(.center)

                if !isActive {
                    Image("AixLabTrademark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88)
                        .foregroundStyle(FocusPalette.textPrimary)
                        .opacity(0.74)
                        .offset(y: 62)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: isActive ? 312 : 252, height: isActive ? 312 : 252)
            .background(isActive ? FocusPalette.ink : FocusPalette.card)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(
                        isActive ? .white.opacity(0.22) : FocusPalette.border,
                        style: StrokeStyle(lineWidth: 1, dash: isActive ? [] : [6, 6])
                    )
            }
            .overlay {
                Circle()
                    .stroke(isActive ? .white.opacity(0.12) : FocusPalette.accent.opacity(0.4), lineWidth: 1)
                    .scaleEffect(isBreathing ? 1.045 : 1.0)
                    .opacity(isBreathing ? 0.2 : 0.7)
            }
            .scaleEffect(isBreathing ? 1.008 : 0.996)
            .animation(.spring(response: 0.5, dampingFraction: 0.86), value: isActive)
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: isBreathing)
        }
        .buttonStyle(.plain)
        .onAppear {
            isBreathing = true
        }
        .onDisappear {
            isBreathing = false
        }
    }
}

struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    let onSelect: (AppTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.focus, title: "专注", icon: "clock")
            tabButton(.todos, title: "待办", icon: "checkmark.circle")
            tabButton(.settings, title: "设置", icon: "gearshape")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(height: 88)
        .background(FocusPalette.paper)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(FocusPalette.border)
                .frame(height: 1)
        }
    }

    private func tabButton(_ tab: AppTab, title: String, icon: String) -> some View {
        Button {
            selectedTab = tab
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? "\(icon).fill" : icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == tab ? FocusPalette.textPrimary : FocusPalette.textSecondary)
            .overlay(alignment: .top) {
                if selectedTab == tab {
                    Rectangle()
                        .fill(FocusPalette.accent)
                        .frame(width: 34, height: 4)
                        .offset(y: -12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
