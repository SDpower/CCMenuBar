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

    /// 顯示名稱
    var displayName: String {
        switch self {
        case .fiveHour:         return "5 小時"
        case .sevenDay:         return "7 天"
        case .sevenDaySonnet:   return "7 天 Sonnet"
        case .sevenDayOpus:     return "7 天 Opus"
        case .sevenDayOauthApps: return "7 天 OAuth Apps"
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
            return "找不到 OAuth Token，請確認已登入 Claude Code"
        case .invalidResponse:
            return "無效的 API 回應"
        case .httpError(let code):
            // 401 表示 token 過期或無效
            if code == 401 {
                return "認證失敗（\(code)），請重新登入 Claude Code"
            }
            return "HTTP 錯誤：\(code)"
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
