//
//  DeviceActivityMonitorExtension.swift
//  whitespaceDeviceActivityMonitor
//
//  用途：DeviceActivity 扩展入口，在系统计划区间结束时兜底清理专注屏蔽策略。
//

import DeviceActivity
import ManagedSettings

final class FocusDeviceActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("whitespace.focus.store"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.clearAllSettings()
    }
}
