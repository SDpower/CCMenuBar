//
//  UsageViewModel.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import Foundation
import Observation
import SwiftUI

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

    /// 要在 Menu Bar 文字區顯示的類別（逗號分隔的 rawValue，持久化存入 UserDefaults）
    @ObservationIgnored
    @AppStorage("menuBarCategories") var menuBarCategoriesRaw: String = UsageCategory.fiveHour.rawValue

    /// 儀表盤圖示所對應的類別（持久化存入 UserDefaults）
    @ObservationIgnored
    @AppStorage("gaugeCategory") var gaugeCategoryRaw: String = UsageCategory.fiveHour.rawValue

    /// Menu Bar 顯示文字（如 "5h:8% 7d:36%"）
    var menuBarText: String {
        let selectedKeys = Set(menuBarCategoriesRaw.split(separator: ",").map(String.init))
        let parts = usageItems
            .filter { selectedKeys.contains($0.category.rawValue) }
            .map { "\($0.category.shortLabel):\(Int($0.info.utilization.rounded()))%" }
        return parts.isEmpty ? "—" : parts.joined(separator: " ")
    }

    /// 依照指定類別的用量，回傳對應的儀表盤 SF Symbol 名稱
    var gaugeSymbol: String {
        guard let item = usageItems.first(where: { $0.category.rawValue == gaugeCategoryRaw }) else {
            return "gauge.with.dots.needle.bottom.0percent"
        }
        switch item.info.utilization {
        case 0..<15:   return "gauge.with.dots.needle.bottom.0percent"
        case 15..<65:  return "gauge.with.dots.needle.bottom.50percent"
        default:       return "gauge.with.dots.needle.bottom.100percent"
        }
    }

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
