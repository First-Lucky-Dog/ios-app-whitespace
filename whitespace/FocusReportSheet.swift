//
//  FocusReportSheet.swift
//  whitespace
//
//  用途：实现专注结束后的成果汇报半屏 Sheet。
//

import SwiftUI

struct FocusReportSheet: View {
    let summary: FocusSummary
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    Rectangle()
                        .fill(FocusPalette.accent)
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(FocusPalette.accentOn)
                }
                VStack(spacing: 4) {
                    Text("专注成功")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(FocusPalette.textPrimary)
                    Text("每一次克制，都是对自我的重塑")
                        .font(.focusCaption)
                        .foregroundStyle(FocusPalette.textSecondary)
                }
            }
            .padding(.top, 34)
            .padding(.bottom, 32)

            IOSListGroup {
                IOSListRow {
                    Text("本次时长")
                        .font(.system(size: 15))
                        .foregroundStyle(FocusPalette.textSecondary)
                } trailing: {
                    Text(summary.durationSeconds.focusDurationText)
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(FocusPalette.textPrimary)
                }
                DividerLine()
                VStack(alignment: .leading, spacing: 6) {
                    Text("完成目标")
                        .font(.system(size: 15))
                        .foregroundStyle(FocusPalette.textSecondary)
                    Text(summary.target)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(FocusPalette.textPrimary)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }

            Spacer()
            PrimaryButton(title: "确认", action: onConfirm)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, FocusLayout.pageHorizontalPadding)
        .background(FocusPalette.background)
    }
}
