//
//  ContentView.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

/// Menu Bar 彈出視窗的主要內容
struct ContentView: View {
    @State private var viewModel = UsageViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題列
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Claude 使用量")
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
                    Text("載入中...")
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
                    Text("更新於 \(lastUpdated.formatted(date: .omitted, time: .standard))")
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

            // 結束按鈕
            Button("結束 CCMenuBar") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .font(.caption)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}

#Preview {
    ContentView()
}
