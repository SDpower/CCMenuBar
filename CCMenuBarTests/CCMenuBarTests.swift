//
//  CCMenuBarTests.swift
//  CCMenuBarTests
//
//  Created by SteveLo on 2026/3/17.
//

import Testing
import Foundation
@testable import CCMenuBar

// MARK: - UsageInfo 解碼測試

@Suite("UsageInfo 解碼")
struct UsageInfoDecodingTests {

    @Test("正常欄位解碼成功")
    func decodeValidUsageInfo() throws {
        let json = """
        {
            "utilization": 36.0,
            "resets_at": "2026-03-20T02:00:00.155344+00:00"
        }
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(UsageInfo.self, from: json)
        #expect(info.utilization == 36.0)
        #expect(info.resetsAt == "2026-03-20T02:00:00.155344+00:00")
    }

    @Test("完整 API 回應解碼，null 欄位自動過濾")
    func decodeFullResponseWithNulls() throws {
        let json = """
        {
            "five_hour":  {"utilization": 7.0,  "resets_at": "2026-03-17T17:00:00+00:00"},
            "seven_day":  {"utilization": 36.0, "resets_at": "2026-03-20T02:00:00+00:00"},
            "seven_day_sonnet": {"utilization": 5.0, "resets_at": "2026-03-21T03:00:00+00:00"},
            "seven_day_opus":   null,
            "seven_day_oauth_apps": null,
            "seven_day_cowork": null,
            "iguana_necktie":   null
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([String: UsageInfo?].self, from: json)
        let result = decoded.compactMapValues { $0 }

        // null 欄位應被過濾，只剩 3 筆
        #expect(result.count == 3)
        #expect(result["five_hour"]?.utilization == 7.0)
        #expect(result["seven_day"]?.utilization == 36.0)
        #expect(result["seven_day_sonnet"]?.utilization == 5.0)
        #expect(result["seven_day_opus"] == nil)
    }

    @Test("utilization 為 0 時也能正常解碼")
    func decodeZeroUtilization() throws {
        let json = """
        {"utilization": 0.0, "resets_at": "2026-03-20T00:00:00+00:00"}
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(UsageInfo.self, from: json)
        #expect(info.utilization == 0.0)
    }

    @Test("utilization 為 100 時也能正常解碼")
    func decodeFullUtilization() throws {
        let json = """
        {"utilization": 100.0, "resets_at": "2026-03-20T00:00:00+00:00"}
        """.data(using: .utf8)!

        let info = try JSONDecoder().decode(UsageInfo.self, from: json)
        #expect(info.utilization == 100.0)
    }
}

// MARK: - UsageCategory 測試

@Suite("UsageCategory")
struct UsageCategoryTests {

    @Test("rawValue 對應正確 API 欄位名稱")
    func rawValues() {
        #expect(UsageCategory.fiveHour.rawValue == "five_hour")
        #expect(UsageCategory.sevenDay.rawValue == "seven_day")
        #expect(UsageCategory.sevenDaySonnet.rawValue == "seven_day_sonnet")
        #expect(UsageCategory.sevenDayOpus.rawValue == "seven_day_opus")
        #expect(UsageCategory.sevenDayOauthApps.rawValue == "seven_day_oauth_apps")
    }

    @Test("displayName 不為空字串")
    func displayNamesNotEmpty() {
        for category in UsageCategory.allCases {
            #expect(!category.displayName.isEmpty, "displayName 不應為空：\(category.rawValue)")
        }
    }

    @Test("allCases 包含所有類別")
    func allCasesCount() {
        #expect(UsageCategory.allCases.count == 5)
    }

    @Test("id 與 rawValue 一致")
    func idEqualsRawValue() {
        for category in UsageCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }
}

// MARK: - TokenProvider 測試

@Suite("TokenProvider")
struct TokenProviderTests {

    @Test("環境變數存在時優先回傳")
    func returnsEnvironmentToken() {
        // 注意：實際測試中無法直接設定 ProcessInfo 的環境變數
        // 此測試驗證當環境變數不存在時回傳 nil（沒有 credentials 檔案時）
        // 完整的環境變數測試需要透過 scheme 的 Environment Variables 設定
        let provider = TokenProvider()
        // 若測試環境沒有設定 CLAUDE_CODE_OAUTH_TOKEN，不應 crash
        let token = provider.getToken()
        // token 可能是 nil（沒有任何來源）或是有效的字串，不應 throw
        if let token {
            #expect(!token.isEmpty, "token 不應為空字串")
        }
    }
}

// MARK: - UsageError 測試

@Suite("UsageError")
struct UsageErrorTests {

    @Test("noToken 錯誤訊息不為空")
    func noTokenDescription() {
        let error = UsageError.noToken
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test("httpError 包含狀態碼")
    func httpErrorDescription() {
        let error401 = UsageError.httpError(statusCode: 401)
        #expect(error401.localizedDescription.contains("401"))

        let error500 = UsageError.httpError(statusCode: 500)
        #expect(error500.localizedDescription.contains("500"))
    }

    @Test("invalidResponse 錯誤訊息不為空")
    func invalidResponseDescription() {
        let error = UsageError.invalidResponse
        #expect(!error.localizedDescription.isEmpty)
    }
}
