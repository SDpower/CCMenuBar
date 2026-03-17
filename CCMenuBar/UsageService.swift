//
//  UsageService.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import Foundation

// MARK: - 使用量類別

/// API 回傳的使用量類別（只顯示有數值的類別）
enum UsageCategory: String, CaseIterable, Identifiable {
    case fiveHour = "five_hour"
    case sevenDay = "seven_day"
    case sevenDaySonnet = "seven_day_sonnet"
    case sevenDayOpus = "seven_day_opus"
    case sevenDayOauthApps = "seven_day_oauth_apps"

    var id: String { rawValue }

    /// 顯示名稱（彈出面板用）
    var displayName: String {
        switch self {
        case .fiveHour:          return String(localized: "5 Hours", comment: "Usage category: 5-hour usage window")
        case .sevenDay:          return String(localized: "7 Days", comment: "Usage category: 7-day usage window")
        case .sevenDaySonnet:    return String(localized: "7 Days Sonnet", comment: "Usage category: 7-day Sonnet model usage")
        case .sevenDayOpus:      return String(localized: "7 Days Opus", comment: "Usage category: 7-day Opus model usage")
        case .sevenDayOauthApps: return String(localized: "7 Days OAuth Apps", comment: "Usage category: 7-day OAuth Apps usage")
        }
    }

    /// 短標籤（Menu Bar 顯示用，須盡量簡短）
    var shortLabel: String {
        switch self {
        case .fiveHour:          return String(localized: "5h", comment: "KEEP SHORT ≤4 chars: Menu bar abbreviation for 5-hour usage")
        case .sevenDay:          return String(localized: "7d", comment: "KEEP SHORT ≤4 chars: Menu bar abbreviation for 7-day usage")
        case .sevenDaySonnet:    return String(localized: "Son", comment: "KEEP SHORT ≤4 chars: Menu bar abbreviation for Sonnet model")
        case .sevenDayOpus:      return String(localized: "Opus", comment: "KEEP SHORT ≤4 chars: Menu bar abbreviation for Opus model")
        case .sevenDayOauthApps: return String(localized: "OAuth", comment: "KEEP SHORT ≤5 chars: Menu bar abbreviation for OAuth Apps")
        }
    }
}

// MARK: - 資料模型

/// 單一類別的使用量資訊
nonisolated struct UsageInfo: Codable, Sendable {
    let utilization: Double
    let resetsAt: String

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

// MARK: - 錯誤定義

/// 使用量 API 相關錯誤
enum UsageError: LocalizedError {
    case noToken
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return String(localized: "OAuth token not found. Please verify you are signed in to Claude Code.",
                          comment: "Error: OAuth token is missing")
        case .invalidResponse:
            return String(localized: "Invalid API response",
                          comment: "Error: API returned unexpected format")
        case .httpError(let code):
            if code == 401 {
                return String(localized: "Authentication failed. Please sign in to Claude Code again.",
                              comment: "Error: HTTP 401 authentication failure")
            }
            if code == 429 {
                return String(localized: "Usage limit reached. Please try again later.",
                              comment: "Error: HTTP 429 rate limit exceeded")
            }
            return String(localized: "HTTP error: \(code)",
                          comment: "Error: Generic HTTP error with status code")
        }
    }
}

// MARK: - API 服務

/// 負責呼叫 Claude API 取得使用量資訊
struct UsageService {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    /// 取得使用量資訊（API 部分欄位可能為 null，會自動過濾）
    func fetchUsage(token: String) async throws -> [String: UsageInfo] {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            // 印出錯誤回應內容以利診斷
            let raw = String(data: data, encoding: .utf8) ?? "(無法讀取)"
            print("[CCMenuBar] HTTP \(httpResponse.statusCode)：\(raw)")
            throw UsageError.httpError(statusCode: httpResponse.statusCode)
        }

        // 只解碼 UsageCategory 已知的 key，忽略 extra_usage 等格式不同的欄位
        let knownKeys = Set(UsageCategory.allCases.map(\.rawValue))
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw UsageError.invalidResponse
        }

        let decoder = JSONDecoder()
        var result: [String: UsageInfo] = [:]
        for key in knownKeys {
            guard let value = root[key], !(value is NSNull) else { continue }
            let itemData = try JSONSerialization.data(withJSONObject: value)
            result[key] = try decoder.decode(UsageInfo.self, from: itemData)
        }
        return result
    }
}
