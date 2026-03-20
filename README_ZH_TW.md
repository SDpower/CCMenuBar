# CCMenuBar

macOS Menu Bar App，透過執行 `claude` CLI 即時顯示 Claude Code 的速率限制狀態。

[English](README.md)

## 功能

- 顯示目前速率限制狀態：**可用** 或 **已達上限**
- Menu Bar 儀表盤圖示動態反映 5 小時視窗的已用時間比例（指針位置隨時間變化）
- 達到速率限制時圖示與文字變為**紅色**，使用超額配額時變為**橘色**
- 顯示速率限制重設的剩餘時間（相對格式，例如「2 小時後」）
- 每 5 分鐘自動刷新，也可手動點擊刷新按鈕
- 找不到 CLI 時顯示安裝提示與直達連結
- 不顯示 Dock 圖示，僅常駐於 Menu Bar
- 支援 12 種語言

## 系統需求

- macOS 15.0+
- 已安裝並登入 [Claude Code](https://claude.ai/download)

## 運作原理

CCMenuBar 執行 `claude` CLI 並帶入 `--verbose --output-format json` 參數，從 JSON 輸出中取得 `rate_limit_event`，解析速率限制狀態與重設時間。App 本身不直接發出任何 API 請求，也不需要 Token 設定。

CLI 依下列路徑順序搜尋：

1. `~/.local/bin/claude`（原生安裝）
2. `~/.claude/bin/claude`
3. `/opt/homebrew/bin/claude`
4. `/usr/local/bin/claude`

## 建置方式

```bash
git clone <repo-url>
cd CCMenuBar
open CCMenuBar.xcodeproj
```

在 Xcode 中選擇 **Product → Run**（⌘R）即可執行。

## 專案結構

```
CCMenuBar/
├── CCMenuBarApp.swift       # App 進入點，Menu Bar Extra 設定
├── ContentView.swift        # 彈出視窗主 UI
├── UsageService.swift       # CLI 執行、JSON 解析與資料模型
├── UsageViewModel.swift     # 狀態管理、自動刷新與儀表盤邏輯
└── UsageRowView.swift       # 速率限制狀態列 UI 元件
```

## 授權

MIT License — 詳見 [LICENSE](LICENSE)

## 作者

[SteveLo](https://github.com/sdpower)
