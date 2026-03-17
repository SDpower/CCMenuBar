//
//  UsageRowView.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

/// 單一使用量類別的顯示列
struct UsageRowView: View {
    let category: UsageCategory
    let info: UsageInfo

    /// utilization 為百分比值（0~100），轉換為 0~1 的小數
    private var fraction: Double { min(info.utilization / 100.0, 1.0) }

    /// 根據使用率回傳對應顏色
    private var utilizationColor: Color {
        switch fraction {
        case 0..<0.5:    return .green
        case 0.5..<0.8:  return .yellow
        case 0.8..<0.95: return .orange
        default:         return .red
        }
    }

    /// 格式化重設時間為相對時間描述
    private var resetTimeText: String {
        let formatter = ISO8601DateFormatter()

        // 嘗試帶小數秒格式，再嘗試標準格式
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: info.resetsAt)

        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: info.resetsAt)
        }

        guard let date else { return info.resetsAt }

        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(verbatim: "\(Int(info.utilization.rounded()))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(utilizationColor)
            }

            // 使用率進度條
            ProgressView(value: fraction, total: 1.0)
                .tint(utilizationColor)

            // 重設時間
            Text("Resets: \(resetTimeText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
