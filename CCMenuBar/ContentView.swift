//
//  ContentView.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

/// Menu Bar 彈出視窗的主要內容
struct ContentView: View {
    var viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Claude Usage")
                    .font(.headline)
                Spacer()
                // 手動刷新按鈕
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            Divider()

            // 依載入狀態顯示不同內容
            switch viewModel.state {
            case .idle, .loading:
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    Spacer()
                }
                .padding(.vertical, 8)

            case .loaded:
                ForEach(viewModel.usageItems, id: \.category) { item in
                    UsageRowView(category: item.category, info: item.info)
                }

                if let lastUpdated = viewModel.lastUpdated {
                    let timeString = lastUpdated.formatted(date: .omitted, time: .standard)
                    Text("Updated at \(timeString)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

            case .error(let message):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Divider()

            // Menu Bar 顯示設定
            VStack(alignment: .leading, spacing: 6) {
                Text("Menu Bar Display")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 文字顯示：勾選要顯示的指標
                ForEach(UsageCategory.allCases) { category in
                    Toggle(isOn: categoryBinding(category)) {
                        Text(category.displayName)
                            .font(.caption)
                    }
                    .toggleStyle(.checkbox)
                }

                Divider()
                    .padding(.vertical, 2)

                // 儀表盤圖示來源
                HStack {
                    Text("Gauge Indicator")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.gaugeCategoryRaw },
                        set: { viewModel.gaugeCategoryRaw = $0 }
                    )) {
                        ForEach(UsageCategory.allCases) { category in
                            Text(category.displayName).tag(category.rawValue)
                        }
                    }
                    .labelsHidden()
                    .font(.caption)
                    .frame(width: 120)
                }
            }

            Divider()

            // 結束按鈕
            Button("Quit CCMenuBar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .font(.caption)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            // 若尚未載入資料則立即刷新（通常 App 啟動時已由 label .task 啟動）
            if viewModel.usageItems.isEmpty {
                viewModel.startAutoRefresh()
            }
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }

    /// 為特定類別建立勾選 Binding，連動 menuBarCategoriesRaw
    private func categoryBinding(_ category: UsageCategory) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.menuBarCategoriesRaw
                    .split(separator: ",")
                    .map(String.init)
                    .contains(category.rawValue)
            },
            set: { isOn in
                var keys = viewModel.menuBarCategoriesRaw
                    .split(separator: ",")
                    .map(String.init)
                    .filter { !$0.isEmpty }
                if isOn {
                    if !keys.contains(category.rawValue) {
                        keys.append(category.rawValue)
                    }
                } else {
                    keys.removeAll { $0 == category.rawValue }
                }
                viewModel.menuBarCategoriesRaw = keys.joined(separator: ",")
            }
        )
    }
}

#Preview {
    ContentView(viewModel: UsageViewModel())
}
