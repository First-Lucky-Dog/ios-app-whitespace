//
//  FocusDialogs.swift
//  whitespace
//
//  用途：实现专注目标、结束确认、清空数据等 iOS 风格弹窗。
//

import SwiftUI

struct GoalPromptView: View {
    @Binding var target: String
    @Binding var skipFuture: Bool
    let onSkip: () -> Void
    let onStart: () -> Void

    var body: some View {
        IOSAlertCard {
            VStack(spacing: 12) {
                Text("确立专注目标")
                    .font(.system(size: 18, weight: .semibold))
                Text("在此次锁定期间，你计划完成什么？")
                    .font(.system(size: 13))
                    .lineSpacing(2)
                TextField("输入任务（选填）...", text: $target)
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(FocusPalette.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .stroke(FocusPalette.border, lineWidth: 1)
                    }
                Toggle(isOn: $skipFuture) {
                    Text("以后直接进入专注")
                        .font(.system(size: 11))
                        .foregroundStyle(FocusPalette.textSecondary)
                }
                .toggleStyle(.checkbox)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        } buttons: {
            AlertActionButton(title: "跳过", action: onSkip)
            AlertActionButton(title: "开始", isBold: true, action: onStart)
        }
    }
}

struct ExitFocusPromptView: View {
    let onContinue: () -> Void
    let onExit: () -> Void

    var body: some View {
        IOSAlertCard {
            VStack(spacing: 6) {
                Text("确定要结束专注吗？")
                    .font(.system(size: 17, weight: .semibold))
                Text("坚持就是胜利，当前未加入允许列表的 App 仍处于锁定状态。")
                    .font(.system(size: 13))
                    .lineSpacing(2)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        } buttons: {
            AlertActionButton(title: "继续保持", isBold: true, action: onContinue)
            AlertActionButton(title: "确定结束", tint: FocusPalette.danger, action: onExit)
        }
    }
}

struct ResetPromptView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        IOSAlertCard {
            VStack(spacing: 6) {
                Text("确定重置吗？")
                    .font(.system(size: 17, weight: .semibold))
                Text("待办、历史专注记录和本地偏好都会被清空。")
                    .font(.system(size: 13))
                    .lineSpacing(2)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        } buttons: {
            AlertActionButton(title: "取消", action: onCancel)
            AlertActionButton(title: "清空", tint: FocusPalette.danger, isBold: true, action: onConfirm)
        }
    }
}

struct IOSAlertCard<BodyContent: View, Buttons: View>: View {
    @ViewBuilder let content: BodyContent
    @ViewBuilder let buttons: Buttons

    var body: some View {
        VStack(spacing: 0) {
            content
            Rectangle()
                .fill(FocusPalette.border)
                .frame(height: 1)
            HStack(spacing: 0) {
                buttons
            }
            .frame(height: 44)
        }
        .frame(maxWidth: 286)
        .background(FocusPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(FocusPalette.border, lineWidth: 1)
        }
        .transition(.scale(scale: 1.08).combined(with: .opacity))
    }
}

struct AlertActionButton: View {
    let title: String
    var tint: Color = FocusPalette.textPrimary
    var isBold = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isBold ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(FocusPalette.border)
                .frame(width: 1)
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundStyle(configuration.isOn ? FocusPalette.accent : FocusPalette.textSecondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}
