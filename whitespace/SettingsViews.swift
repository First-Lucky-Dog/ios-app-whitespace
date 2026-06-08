//
//  SettingsViews.swift
//  whitespace
//
//  用途：实现设置页、历史记录列表和设置页导航行。
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    let records: [FocusRecord]
    @Binding var skipGoalPrompt: Bool
    let screenTimeSummary: String
    let blocklistSummary: String
    let onConfigureWhitelist: () -> Void
    let onConfigureBlocklist: () -> Void
    let onRecovery: () -> Void
    let onPrivacy: () -> Void
    let onReset: () -> Void
    let onBackHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(eyebrow: "PREFERENCES", title: "设置")

                VStack(alignment: .leading, spacing: 6) {
                    Text("关于“双层防护”")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FocusPalette.textPrimary)
                    Text("开启专注模式后，系统会锁定未加入允许列表的 App，并额外强制屏蔽重点 App。强制屏蔽优先于允许列表。\(screenTimeSummary)")
                        .font(.system(size: 13))
                        .foregroundStyle(FocusPalette.textSecondary)
                        .lineSpacing(3)
                }
                .padding(16)
                .iosCard()

                SectionHeader(title: "交互偏好")
                IOSListGroup {
                    IOSListRow {
                        ListLabel(title: "锁定前确立目标", subtitle: "开启专注前弹出目标输入框")
                    } trailing: {
                        SmallPillButton(title: skipGoalPrompt ? "已关闭" : "已开启", isActive: !skipGoalPrompt) {
                            skipGoalPrompt.toggle()
                        }
                    }
                }

                SectionHeader(title: "历史专注记录")
                IOSListGroup {
                    if records.isEmpty {
                        Text("暂无历史自律数据")
                            .font(.system(size: 14))
                            .foregroundStyle(FocusPalette.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(20)
                    } else {
                        ForEach(Array(records.enumerated()), id: \.element.persistentModelID) { index, record in
                            HistoryRecordRow(record: record)
                            if index < records.count - 1 {
                                DividerLine()
                            }
                        }
                    }
                }

                SectionHeader(title: "系统高级工具")
                IOSListGroup {
                    NavigationStyleRow(title: "自定义允许使用的 App/网站", action: onConfigureWhitelist)
                    DividerLine()
                    NavigationStyleRow(title: "强制屏蔽 App 与网站", subtitle: blocklistSummary, action: onConfigureBlocklist)
                    DividerLine()
                    NavigationStyleRow(title: "应急防沉迷恢复", action: onRecovery)
                    DividerLine()
                    NavigationStyleRow(title: "数据与隐私合规说明", action: onPrivacy)
                }

                IOSListGroup {
                    Button(action: onReset) {
                        Text("清空本地所有自律数据")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(FocusPalette.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.plain)
                }

                GhostButton(title: "返回专注首页", action: onBackHome)
                    .padding(.top, -8)
            }
            .padding(.horizontal, FocusLayout.pageHorizontalPadding)
            .padding(.top, FocusLayout.pageTopPadding)
            .padding(.bottom, FocusLayout.pageBottomPadding)
        }
    }
}

struct HistoryRecordRow: View {
    let record: FocusRecord

    var body: some View {
        IOSListRow {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.target)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(FocusPalette.textPrimary)
                Text(record.startedAt.focusHistoryDateText)
                    .font(.system(size: 12))
                    .foregroundStyle(FocusPalette.textSecondary)
            }
        } trailing: {
            Text(record.durationSeconds.focusDurationText)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(FocusPalette.textPrimary)
        }
    }
}

struct NavigationStyleRow: View {
    let title: String
    var subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            IOSListRow {
                ListLabel(title: title, subtitle: subtitle)
            } trailing: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FocusPalette.textMuted)
            }
        }
        .buttonStyle(.plain)
    }
}
