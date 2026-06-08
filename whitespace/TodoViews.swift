//
//  TodoViews.swift
//  whitespace
//
//  用途：实现今日待办页面、输入栏、待办项和空状态。
//

import SwiftUI

struct TodoListView: View {
    let todos: [TodoItem]
    @Binding var newTodoTitle: String
    let onAdd: () -> Void
    let onToggle: (TodoItem) -> Void

    private var pending: [TodoItem] { todos.filter { !$0.isDone } }
    private var completed: [TodoItem] { todos.filter { $0.isDone } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(eyebrow: "任务清单", title: "今日待办")

                HStack(spacing: 12) {
                    TextField("添加一个新的备忘...", text: $newTodoTitle)
                        .font(.system(size: 17))
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(FocusPalette.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .stroke(FocusPalette.border, lineWidth: 1)
                        }
                        .submitLabel(.done)
                        .onSubmit(onAdd)

                    Button(action: onAdd) {
                        Text("添加")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(FocusPalette.accentOn)
                            .frame(width: 72, height: 52)
                            .background(FocusPalette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                    }
                    .pressableScale()
                }

                if pending.isEmpty {
                    EmptyStateView(text: "今日无待办任务")
                } else {
                    VStack(spacing: 12) {
                        ForEach(pending) { todo in
                            TodoRow(todo: todo) { onToggle(todo) }
                        }
                    }
                }

                if !completed.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("已完成")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(FocusPalette.textSecondary)
                        ForEach(completed) { todo in
                            TodoRow(todo: todo) { onToggle(todo) }
                                .opacity(0.55)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, FocusLayout.pageHorizontalPadding)
            .padding(.top, FocusLayout.pageTopPadding)
            .padding(.bottom, FocusLayout.pageBottomPadding)
        }
    }
}

struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    Rectangle()
                        .stroke(todo.isDone ? FocusPalette.accent : FocusPalette.textMuted, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if todo.isDone {
                        Rectangle()
                            .fill(FocusPalette.accent)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(FocusPalette.accentOn)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.system(size: 15))
                .foregroundStyle(todo.isDone ? FocusPalette.textSecondary : FocusPalette.textPrimary)
                .strikethrough(todo.isDone, color: FocusPalette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(FocusPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .stroke(FocusPalette.border, lineWidth: 1)
        }
    }
}

struct EmptyStateView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(FocusPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
    }
}
