//
//  TokenProvider.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import Foundation
import Security

/// 負責按優先順序從三個來源讀取 OAuth Token
struct TokenProvider {

    /// 按優先順序嘗試取得 token
    /// 1. 環境變數 CLAUDE_CODE_OAUTH_TOKEN
    /// 2. ~/.claude/.credentials.json
    /// 3. macOS Keychain（服務名稱：Claude Code-credentials）
    func getToken() -> String? {
        if let token = fromEnvironment() {
            return token
        }
        if let token = fromCredentialsFile() {
            return token
        }
        if let token = fromKeychain() {
            return token
        }
        return nil
    }

    // MARK: - 來源 1：環境變數

    private func fromEnvironment() -> String? {
        ProcessInfo.processInfo.environment["CLAUDE_CODE_OAUTH_TOKEN"]
    }

    // MARK: - 來源 2：認證檔案

    private func fromCredentialsFile() -> String? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let credentialsURL = homeDir
            .appendingPathComponent(".claude")
            .appendingPathComponent(".credentials.json")

        guard let data = try? Data(contentsOf: credentialsURL) else {
            return nil
        }

        return extractAccessToken(from: data)
    }

    // MARK: - 來源 3：macOS Keychain

    private func fromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        // 嘗試解析 JSON 結構（與 credentials.json 相同格式）
        if let token = extractAccessToken(from: data) {
            return token
        }

        // 若不是 JSON，視為純 token 字串
        return String(data: data, encoding: .utf8)
    }

    // MARK: - 共用解析邏輯

    /// 從 JSON 資料中提取 claudeAiOauth.accessToken
    private func extractAccessToken(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let oauth = json["claudeAiOauth"] as? [String: Any],
            let accessToken = oauth["accessToken"] as? String
        else {
            return nil
        }
        return accessToken
    }
}
