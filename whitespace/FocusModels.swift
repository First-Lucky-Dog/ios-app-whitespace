//
//  FocusModels.swift
//  whitespace
//
//  用途：定义 SwiftData 持久化模型，包括今日待办和专注历史记录。
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String, isDone: Bool = false, createdAt: Date = .now, completedAt: Date? = nil) {
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

@Model
final class FocusRecord {
    var target: String
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: Int

    init(target: String, startedAt: Date, endedAt: Date, durationSeconds: Int) {
        self.target = target
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
    }
}
