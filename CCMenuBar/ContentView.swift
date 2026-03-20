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
                Text(String(localized: "Claude Rate Limit",
                            comment: "Main window title showing Claude rate limit status"))
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
                    Text(String(localized: "Loading...",
                                comment: "Loading indicator text while fetching usage data"))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    Spacer()
                }
                .padding(.vertical, 8)

            case .loaded:
                if let info = viewModel.rateLimitInfo {
                    UsageRowView(info: info)
                }

                if let lastUpdated = viewModel.lastUpdated {
                    let timeString = lastUpdated.formatted(date: .omitted, time: .standard)
                    Text(String(localized: "Updated at \(timeString)",
                                comment: "Timestamp showing when data was last refreshed"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

            case .error(let usageError):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(usageError.errorDescription ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    // cliNotFound 時額外顯示安裝說明連結
                    if case .cliNotFound = usageError {
                        Link(String(localized: "Install Claude Code →",
                                    comment: "Button to open Claude Code installation page"),
                             destination: URL(string: "https://claude.ai/download")!)
                            .font(.caption)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Divider()

            // 結束按鈕
            Button(String(localized: "Quit CCMenuBar",
                          comment: "Button to quit the application")) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .font(.caption)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            if viewModel.rateLimitInfo == nil {
                viewModel.startAutoRefresh()
            }
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}

#Preview {
    ContentView(viewModel: UsageViewModel())
}
