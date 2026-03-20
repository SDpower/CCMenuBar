//
//  UsageService.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import Foundation

// MARK: - Rate Limit 狀態

/// Rate limit 狀態（allowed = 可用，rejected = 已達上限）
enum RateLimitStatus: String, Codable, Sendable {
    case allowed
    case rejected
}

// MARK: - 資料模型

/// 從 claude CLI 解析出的 rate limit 資訊
nonisolated struct RateLimitInfo: Sendable {
    let status: RateLimitStatus
    let resetsAt: Date
    let rateLimitType: String
    let overageStatus: String
    let isUsingOverage: Bool
}

// MARK: - 錯誤定義

/// CLI 執行相關錯誤
enum UsageError: LocalizedError {
    case cliNotFound
    case cliExecutionFailed(String)
    case noRateLimitEvent
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return String(localized: "Claude CLI not found. Please install Claude Code.",
                          comment: "Error: claude CLI not found in expected paths")
        case .cliExecutionFailed(let msg):
            return String(localized: "CLI execution failed: \(msg)",
                          comment: "Error: claude CLI process failed")
        case .noRateLimitEvent:
            return String(localized: "No rate limit data received.",
                          comment: "Error: CLI output contained no rate_limit_event")
        case .parseError(let msg):
            return String(localized: "Failed to parse CLI output: \(msg)",
                          comment: "Error: JSON parsing failure from CLI output")
        }
    }
}

// MARK: - CLI JSON 解碼用中間結構

/// claude CLI JSON 輸出中的事件（只解碼需要的欄位）
private struct CLIEvent: Decodable {
    let type: String
    let rateLimitInfo: CLIRateLimitInfo?

    enum CodingKeys: String, CodingKey {
        case type
        case rateLimitInfo = "rate_limit_info"
    }

    struct CLIRateLimitInfo: Decodable {
        let status: String
        let resetsAt: Int
        let rateLimitType: String
        let overageStatus: String
        let isUsingOverage: Bool
    }
}

// MARK: - CLI 服務

/// 執行 claude CLI 並解析 rate limit 資訊
struct UsageService {

    /// Claude CLI 的搜尋路徑（依優先順序）
    /// native install: ~/.local/bin/claude
    /// homebrew cask: /opt/homebrew/bin/claude 或 /usr/local/bin/claude
    /// 舊版 npm: ~/.claude/bin/claude
    private static let cliSearchPaths: [String] = [
        "\(NSHomeDirectory())/.local/bin/claude",
        "\(NSHomeDirectory())/.claude/bin/claude",
        "/opt/homebrew/bin/claude",
        "/usr/local/bin/claude"
    ]

    /// 找到系統中 claude CLI 的路徑
    private func findCLIPath() -> String? {
        for path in Self.cliSearchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    /// 執行 claude CLI 取得 rate limit 資訊
    func fetchRateLimitInfo() async throws -> RateLimitInfo {
        guard let cliPath = findCLIPath() else {
            throw UsageError.cliNotFound
        }

        let output = try await runCLI(at: cliPath)
        return try parseRateLimitEvent(from: output)
    }

    /// 使用 Process 執行 CLI 指令，回傳 stdout 輸出
    private func runCLI(at path: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = [
                "--verbose",
                "--no-session-persistence",
                "--disable-slash-commands",
                "--strict-mcp-config",
                "--output-format", "json",
                "--model", "haiku",
                "-p", "."
            ]

            // 補充 PATH，確保 Menu Bar App 能找到相依執行檔
            var env = ProcessInfo.processInfo.environment
            let home = NSHomeDirectory()
            var path = env["PATH"] ?? "/usr/bin:/bin"
            path += ":\(home)/.local/bin:\(home)/.claude/bin:/usr/local/bin:/opt/homebrew/bin"
            env["PATH"] = path
            process.environment = env

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            process.terminationHandler = { proc in
                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8) ?? ""

                if proc.terminationStatus != 0 && output.isEmpty {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8) ?? "exit code \(proc.terminationStatus)"
                    continuation.resume(throwing: UsageError.cliExecutionFailed(errMsg))
                } else {
                    continuation.resume(returning: output)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: UsageError.cliExecutionFailed(error.localizedDescription))
            }
        }
    }

    /// 從 CLI JSON 輸出（array 格式）中找到 rate_limit_event 並解析
    private func parseRateLimitEvent(from output: String) throws -> RateLimitInfo {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            throw UsageError.noRateLimitEvent
        }

        // CLI 輸出為 JSON array，每個元素為一個事件
        guard let events = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw UsageError.parseError("Not a JSON array")
        }

        for event in events {
            guard (event["type"] as? String) == "rate_limit_event",
                  let infoDict = event["rate_limit_info"] as? [String: Any],
                  let statusStr = infoDict["status"] as? String,
                  let resetsAtInt = infoDict["resetsAt"] as? Int,
                  let rateLimitType = infoDict["rateLimitType"] as? String,
                  let overageStatus = infoDict["overageStatus"] as? String,
                  let isUsingOverage = infoDict["isUsingOverage"] as? Bool
            else { continue }

            guard let status = RateLimitStatus(rawValue: statusStr) else {
                throw UsageError.parseError("Unknown status: \(statusStr)")
            }

            return RateLimitInfo(
                status: status,
                resetsAt: Date(timeIntervalSince1970: TimeInterval(resetsAtInt)),
                rateLimitType: rateLimitType,
                overageStatus: overageStatus,
                isUsingOverage: isUsingOverage
            )
        }

        throw UsageError.noRateLimitEvent
    }
}
