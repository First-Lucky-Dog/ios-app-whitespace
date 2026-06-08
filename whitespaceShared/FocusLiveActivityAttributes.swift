//
//  FocusLiveActivityAttributes.swift
//  whitespace
//
//  用途：定义专注 Live Activity 在主 App 与 Widget 扩展之间共享的数据模型。
//

import ActivityKit
import Foundation

struct FocusLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var target: String
        var isFinished: Bool
    }

    var focusID: String
    var appURLString: String
}

extension FocusLiveActivityAttributes {
    static let appURLString = "whitespace://focus"
}
