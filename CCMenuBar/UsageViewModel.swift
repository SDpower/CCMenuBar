//
//  UsageViewModel.swift
//  CCMenuBar
//
//  Created by SteveLo on 2026/3/17.
//

import SwiftUI

// MARK: - 載入狀態

enum LoadingState {
    case idle
    case loading
    case loaded
    case error(UsageError)
}

// MARK: - ViewModel

/// 管理 rate limit 資料的 ViewModel，每 5 分鐘自動刷新
@Observable
final class UsageViewModel {

    // MARK: - 公開屬性

    var state: LoadingState = .idle
    var rateLimitInfo: RateLimitInfo?
    var lastUpdated: Date?

    /// Menu Bar 文字：永遠顯示重設剩餘時間
    var menuBarText: String {
        guard let info = rateLimitInfo else { return "—" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: info.resetsAt, relativeTo: Date())
    }

    /// 儀表盤 SF Symbol：依剩餘時間比例顯示刻度（5小時視窗）
    /// rejected 強制顯示 100%
    var gaugeSymbol: String {
        guard let info = rateLimitInfo else {
            return "gauge.with.dots.needle.bottom.0percent"
        }
        if info.status == .rejected {
            return "gauge.with.dots.needle.bottom.100percent"
        }
        // 計算已用比例：(5小時 - 剩餘秒數) / 5小時
        let windowSeconds: TimeInterval = 5 * 3600
        let remaining = max(0, info.resetsAt.timeIntervalSinceNow)
        let usedRatio = 1.0 - (remaining / windowSeconds)
        // 系統只有 0% / 50% / 100% 三個刻度
        switch usedRatio {
        case ..<0.25:  return "gauge.with.dots.needle.bottom.0percent"
        case 0.25..<0.75: return "gauge.with.dots.needle.bottom.50percent"
        default:       return "gauge.with.dots.needle.bottom.100percent"
        }
    }

    /// 儀表盤顏色：rejected = 紅、isUsingOverage = 橘、否則預設
    var gaugeColor: Color {
        guard let info = rateLimitInfo else { return .primary }
        if info.status == .rejected { return .red }
        if info.isUsingOverage { return .orange }
        return .primary
    }

    // MARK: - 私有屬性

    private let usageService = UsageService()
    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 300  // 5 分鐘

    // MARK: - 公開方法

    /// 啟動自動刷新（每 5 分鐘）
    func startAutoRefresh() {
        guard refreshTask == nil || refreshTask?.isCancelled == true else { return }
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

    /// 執行一次刷新
    @MainActor
    func refresh() async {
        state = .loading
        do {
            rateLimitInfo = try await usageService.fetchRateLimitInfo()
            lastUpdated = Date()
            state = .loaded
        } catch {
            print("[CCMenuBar] refresh 失敗：\(error)")
            let usageError = error as? UsageError ?? .cliExecutionFailed(error.localizedDescription)
            state = .error(usageError)
        }
    }
}
