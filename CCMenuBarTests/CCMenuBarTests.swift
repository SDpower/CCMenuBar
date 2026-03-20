//
//  CCMenuBarTests.swift
//  CCMenuBarTests
//
//  Created by SteveLo on 2026/3/17.
//

import Testing
import Foundation
import SwiftUI
@testable import CCMenuBar

// MARK: - RateLimitStatus 測試

@Suite("RateLimitStatus")
struct RateLimitStatusTests {

    @Test("allowed rawValue 正確")
    func allowedRawValue() {
        #expect(RateLimitStatus.allowed.rawValue == "allowed")
    }

    @Test("rejected rawValue 正確")
    func rejectedRawValue() {
        #expect(RateLimitStatus.rejected.rawValue == "rejected")
    }

    @Test("從字串解碼 allowed")
    func decodeAllowed() throws {
        let data = "\"allowed\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(RateLimitStatus.self, from: data)
        #expect(status == .allowed)
    }

    @Test("從字串解碼 rejected")
    func decodeRejected() throws {
        let data = "\"rejected\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(RateLimitStatus.self, from: data)
        #expect(status == .rejected)
    }
}

// MARK: - UsageError 測試

@Suite("UsageError")
struct UsageErrorTests {

    @Test("cliNotFound 錯誤訊息不為空")
    func cliNotFoundDescription() {
        let error = UsageError.cliNotFound
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test("cliExecutionFailed 包含原始訊息")
    func cliExecutionFailedDescription() {
        let msg = "exit code 1: permission denied"
        let error = UsageError.cliExecutionFailed(msg)
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test("noRateLimitEvent 錯誤訊息不為空")
    func noRateLimitEventDescription() {
        let error = UsageError.noRateLimitEvent
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test("parseError 包含原始訊息")
    func parseErrorDescription() {
        let detail = "unexpected null"
        let error = UsageError.parseError(detail)
        #expect(!error.localizedDescription.isEmpty)
    }
}

// MARK: - LoadingState 測試

@Suite("LoadingState")
struct LoadingStateTests {

    @Test("error 狀態帶 UsageError — cliNotFound 可 pattern match")
    func errorCLINotFound() {
        let state = LoadingState.error(.cliNotFound)
        if case .error(let e) = state, case .cliNotFound = e {
            // 正確 pattern match
        } else {
            Issue.record("LoadingState.error(.cliNotFound) pattern match 失敗")
        }
    }

    @Test("error 狀態帶 UsageError — cliExecutionFailed 帶訊息")
    func errorCLIExecutionFailed() {
        let msg = "exit code 1"
        let state = LoadingState.error(.cliExecutionFailed(msg))
        if case .error(let e) = state, case .cliExecutionFailed(let m) = e {
            #expect(m == msg)
        } else {
            Issue.record("LoadingState.error(.cliExecutionFailed) pattern match 失敗")
        }
    }
}

// MARK: - UsageViewModel 測試

@Suite("UsageViewModel")
@MainActor
struct UsageViewModelTests {

    @Test("menuBarText — 無資料時回傳 —")
    func menuBarTextNoData() {
        let vm = UsageViewModel()
        #expect(vm.menuBarText == "—")
    }

    @Test("menuBarText — 有資料時回傳非空字串")
    func menuBarTextWithData() {
        let vm = UsageViewModel()
        vm.rateLimitInfo = RateLimitInfo(
            status: .allowed,
            resetsAt: Date().addingTimeInterval(3600),
            rateLimitType: "five_hour",
            overageStatus: "allowed",
            isUsingOverage: false
        )
        #expect(!vm.menuBarText.isEmpty)
        #expect(vm.menuBarText != "—")
    }

    @Test("gaugeSymbol — 無資料時為 0%")
    func gaugeSymbolNoData() {
        let vm = UsageViewModel()
        #expect(vm.gaugeSymbol == "gauge.with.dots.needle.bottom.0percent")
    }

    @Test("gaugeSymbol — allowed 剩餘接近 5 小時時為 0%")
    func gaugeSymbolAllowedFull() {
        let vm = UsageViewModel()
        // 剩餘 4.9 小時 ≈ 已用 2%，落在 0% 區間
        vm.rateLimitInfo = RateLimitInfo(
            status: .allowed,
            resetsAt: Date().addingTimeInterval(4.9 * 3600),
            rateLimitType: "five_hour",
            overageStatus: "allowed",
            isUsingOverage: false
        )
        #expect(vm.gaugeSymbol == "gauge.with.dots.needle.bottom.0percent")
    }

    @Test("gaugeSymbol — allowed 剩餘約 2.5 小時時為 50%")
    func gaugeSymbolAllowedHalf() {
        let vm = UsageViewModel()
        // 剩餘 2.5 小時 = 已用 50%
        vm.rateLimitInfo = RateLimitInfo(
            status: .allowed,
            resetsAt: Date().addingTimeInterval(2.5 * 3600),
            rateLimitType: "five_hour",
            overageStatus: "allowed",
            isUsingOverage: false
        )
        #expect(vm.gaugeSymbol == "gauge.with.dots.needle.bottom.50percent")
    }

    @Test("gaugeSymbol — rejected 時強制為 100%")
    func gaugeSymbolRejected() {
        let vm = UsageViewModel()
        vm.rateLimitInfo = RateLimitInfo(
            status: .rejected,
            resetsAt: Date().addingTimeInterval(3600),
            rateLimitType: "five_hour",
            overageStatus: "rejected",
            isUsingOverage: true
        )
        #expect(vm.gaugeSymbol == "gauge.with.dots.needle.bottom.100percent")
    }

    @Test("gaugeColor — 無資料時為 primary")
    func gaugeColorNoData() {
        let vm = UsageViewModel()
        #expect(vm.gaugeColor == .primary)
    }

    @Test("gaugeColor — rejected 時為紅色")
    func gaugeColorRejected() {
        let vm = UsageViewModel()
        vm.rateLimitInfo = RateLimitInfo(
            status: .rejected,
            resetsAt: Date().addingTimeInterval(3600),
            rateLimitType: "five_hour",
            overageStatus: "rejected",
            isUsingOverage: false
        )
        #expect(vm.gaugeColor == .red)
    }

    @Test("gaugeColor — isUsingOverage 時為橘色")
    func gaugeColorOverage() {
        let vm = UsageViewModel()
        vm.rateLimitInfo = RateLimitInfo(
            status: .allowed,
            resetsAt: Date().addingTimeInterval(3600),
            rateLimitType: "five_hour",
            overageStatus: "allowed",
            isUsingOverage: true
        )
        #expect(vm.gaugeColor == .orange)
    }

    @Test("gaugeColor — 正常 allowed 時為 primary")
    func gaugeColorNormal() {
        let vm = UsageViewModel()
        vm.rateLimitInfo = RateLimitInfo(
            status: .allowed,
            resetsAt: Date().addingTimeInterval(3600),
            rateLimitType: "five_hour",
            overageStatus: "allowed",
            isUsingOverage: false
        )
        #expect(vm.gaugeColor == .primary)
    }
}

// MARK: - RateLimitInfo 建構測試

@Suite("RateLimitInfo")
struct RateLimitInfoTests {

    @Test("allowed 狀態 resetsAt 保留正確")
    func allowedInfo() {
        let date = Date(timeIntervalSince1970: 1774044000)
        let info = RateLimitInfo(
            status: .allowed,
            resetsAt: date,
            rateLimitType: "five_hour",
            overageStatus: "rejected",
            isUsingOverage: false
        )
        #expect(info.status == .allowed)
        #expect(info.resetsAt == date)
        #expect(info.rateLimitType == "five_hour")
        #expect(info.isUsingOverage == false)
    }

    @Test("rejected 狀態建構正確")
    func rejectedInfo() {
        let date = Date(timeIntervalSince1970: 1774044000)
        let info = RateLimitInfo(
            status: .rejected,
            resetsAt: date,
            rateLimitType: "five_hour",
            overageStatus: "rejected",
            isUsingOverage: true
        )
        #expect(info.status == .rejected)
        #expect(info.isUsingOverage == true)
    }
}
