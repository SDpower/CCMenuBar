//
//  CCMenuBarApp.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

@main
struct CCMenuBarApp: App {
    // ViewModel 提升到 App 層級，讓 Menu Bar label 與彈出面板共用同一份資料
    @State private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            // 直接在 Menu Bar 顯示儀表盤圖示 + 用量數字
            HStack(spacing: 4) {
                Image(systemName: viewModel.gaugeSymbol)
                    .foregroundStyle(viewModel.gaugeColor)
                Text(viewModel.menuBarText)
                    .monospacedDigit()
                    .foregroundStyle(viewModel.gaugeColor)
            }
            // App 啟動時立即開始自動刷新，不等 ContentView 開啟
            .task {
                viewModel.startAutoRefresh()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
