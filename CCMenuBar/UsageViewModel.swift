//
//  UsageViewModel.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import Foundation
import Observation

// MARK: - 載入狀態

/// 使用量資料的載入狀態
enum LoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - ViewModel

/// 管理使用量資料狀態與自動刷新
@Observable
final class UsageViewModel {

    // MARK: - 公開屬性

    var state: LoadingState = .idle
    var usageItems: [(category: UsageCategory, info: UsageInfo)] = []
    var lastUpdated: Date?

    // MARK: - 私有屬性

    private let tokenProvider = TokenProvider()
    private let usageService = UsageService()
    private var refreshTask: Task<Void, Never>?

    /// 自動刷新間隔（秒）
    private let refreshInterval: TimeInterval = 300

    // MARK: - 公開方法

    /// 啟動自動刷新，立即執行一次後每 60 秒重複
    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(refreshInterval))
            }
        }
    }

    /// 停止自動刷新
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// 手動刷新
    func refresh() async {
        state = .loading

        guard let token = tokenProvider.getToken() else {
            state = .error(UsageError.noToken.localizedDescription)
            return
        }

        do {
            let response = try await usageService.fetchUsage(token: token)

            // 按 UsageCategory.allCases 順序整理資料
            usageItems = UsageCategory.allCases.compactMap { category in
                guard let info = response[category.rawValue] else { return nil }
                return (category: category, info: info)
            }

            lastUpdated = Date()
            state = .loaded
        } catch {
            print("[CCMenuBar] refresh 失敗：\(error)")
            state = .error(error.localizedDescription)
        }
    }
}
