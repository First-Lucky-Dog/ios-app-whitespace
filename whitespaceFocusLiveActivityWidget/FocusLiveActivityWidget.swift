//
//  FocusLiveActivityWidget.swift
//  whitespaceFocusLiveActivityWidget
//
//  用途：绘制专注实时活动在锁屏、主屏幕横幅和灵动岛中的界面。
//

import ActivityKit
import SwiftUI
import WidgetKit

private enum LiveActivityPalette {
    static let ink = Color(red: 10.0 / 255.0, green: 10.0 / 255.0, blue: 10.0 / 255.0)
    static let accent = Color(red: 197.0 / 255.0, green: 232.0 / 255.0, blue: 3.0 / 255.0)
}

@main
struct FocusLiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusLiveActivityWidget()
    }
}

struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusLiveActivityAttributes.self) { context in
            FocusLockScreenLiveActivityView(context: context)
                .activityBackgroundTint(LiveActivityPalette.ink)
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: context.attributes.appURLString))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        FocusIslandMark(size: 24)
                        FocusLiveTimerText(startedAt: context.state.startedAt, size: 20, weight: .semibold)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        FocusElapsedPrompt(startedAt: context.state.startedAt, size: 12, alignment: .center)
                        FocusIslandExpandedFooter(target: context.state.target)
                    }
                }
            } compactLeading: {
                FocusIslandCompactSource()
            } compactTrailing: {
                FocusIslandCompactCluster(startedAt: context.state.startedAt)
            } minimal: {
                FocusIslandMark(size: 21)
            }
            .widgetURL(URL(string: context.attributes.appURLString))
            .keylineTint(LiveActivityPalette.accent)
            .contentMargins(.all, 0, for: .compactTrailing)
        }
        .configurationDisplayName("不刷了状态")
        .description("在锁屏和灵动岛显示当前专注计时。")
    }
}

private struct FocusLockScreenLiveActivityView: View {
    let context: ActivityViewContext<FocusLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            FocusIslandMark(size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(context.state.isFinished ? "专注结束" : "正在专注")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LiveActivityPalette.accent)
                Text(context.state.target)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("轻触返回应用")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                FocusElapsedPrompt(startedAt: context.state.startedAt, size: 12, alignment: .leading)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                FocusLiveTimerText(startedAt: context.state.startedAt, size: 22, weight: .bold)
                Text("已专注")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
    }
}

private struct FocusLiveTimerText: View {
    let startedAt: Date
    let size: CGFloat
    let weight: Font.Weight

    var body: some View {
        Text(startedAt, style: .timer)
            .font(.system(size: size, weight: weight, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
    }
}

private struct FocusIslandCompactSource: View {
    var body: some View {
        Text("不刷")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.84))
            .padding(.leading, 2)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct FocusIslandCompactCluster: View {
    let startedAt: Date

    var body: some View {
        HStack(spacing: 3) {
            FocusIslandMark(size: 13)
            Text("专注")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.66))
            Text(startedAt, style: .timer)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .lineLimit(1)
        .minimumScaleFactor(0.74)
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct FocusIslandExpandedFooter: View {
    let target: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LiveActivityPalette.accent)

            Text(target)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)

            Spacer(minLength: 0)

            FocusBreathingDots()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 0, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
        .padding(.top, 2)
    }
}

private struct FocusElapsedPrompt: View {
    let startedAt: Date
    let size: CGFloat
    let alignment: TextAlignment

    var body: some View {
        HStack(spacing: 0) {
            Text("您已专注 ")
                .foregroundStyle(.white.opacity(0.5))
            Text(startedAt, style: .timer)
                .foregroundStyle(.white.opacity(0.82))
        }
        .font(.system(size: size, weight: .medium, design: .rounded))
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        .multilineTextAlignment(alignment)
        .lineLimit(1)
    }
}

private struct FocusBreathingDots: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let second = Calendar.current.component(.second, from: timeline.date)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(LiveActivityPalette.accent.opacity((second + index).isMultiple(of: 3) ? 1 : 0.35))
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: second)
        }
    }
}

private struct FocusIslandMark: View {
    let size: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let second = Calendar.current.component(.second, from: timeline.date)
            let isBreathing = second.isMultiple(of: 2)

            ZStack {
                Circle()
                    .fill(LiveActivityPalette.accent.opacity(isBreathing ? 0.24 : 0.12))
                    .scaleEffect(isBreathing ? 1 : 0.86)
                Circle()
                    .stroke(LiveActivityPalette.accent.opacity(0.72), lineWidth: max(1.2, size * 0.06))
                    .padding(size * 0.12)
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.34, height: size * 0.34)
            }
            .frame(width: size, height: size)
            .animation(.easeInOut(duration: 0.9), value: isBreathing)
        }
    }
}
