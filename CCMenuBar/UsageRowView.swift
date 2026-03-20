//
//  UsageRowView.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

/// 顯示 rate limit 狀態的列
struct UsageRowView: View {
    let info: RateLimitInfo

    /// 狀態文字
    private var statusText: String {
        switch info.status {
        case .allowed:
            return String(localized: "Available",
                          comment: "Rate limit status: requests are allowed")
        case .rejected:
            return String(localized: "Rate Limited",
                          comment: "Rate limit status: requests are rejected")
        }
    }

    /// 狀態顏色
    private var statusColor: Color {
        switch info.status {
        case .allowed:  return .green
        case .rejected: return .red
        }
    }

    /// 重設時間的相對描述
    private var resetTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: info.resetsAt, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(localized: "5 Hours",
                            comment: "Usage category: 5-hour usage window"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                // 狀態圓點 + 文字
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }
            }

            // 重設時間
            Text(String(localized: "Resets: \(resetTimeText)",
                        comment: "Shows when the usage counter will reset, e.g. 'Resets: in 3 hours'"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
