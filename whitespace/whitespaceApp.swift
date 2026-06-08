//
//  whitespaceApp.swift
//  whitespace
//
//  用途：应用入口，配置 SwiftData 容器并挂载根视图。
//

import SwiftUI
import SwiftData

@main
struct whitespaceApp: App {
    private let sharedModelContainer: ModelContainer?

    init() {
        let schema = Schema([
            TodoItem.self,
            FocusRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            sharedModelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                ContentView()
                    .modelContainer(sharedModelContainer)
            } else {
                StartupFailureView()
            }
        }
    }
}

private struct StartupFailureView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.orange)
            Text("本地数据暂时无法打开")
                .font(.system(size: 18, weight: .semibold))
            Text("请重启应用。如果问题持续存在，请重新安装后再试。")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
