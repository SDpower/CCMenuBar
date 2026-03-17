# CCMenuBar

macOS Menu Bar App，即時顯示 Claude Code 的 API 用量限制。

[English](README.md)

## 功能

- 顯示四種用量指標：5 小時、7 天、7 天 Sonnet、7 天 Opus
- 進度條顏色依用量變化（綠 / 黃 / 橙 / 紅）
- 顯示每個指標的重設時間
- 每 5 分鐘自動刷新，也可手動點擊刷新
- 不顯示 Dock 圖示，僅常駐於 Menu Bar

## 系統需求

- macOS 26.2+
- 已安裝並登入 [Claude Code](https://claude.ai/download)

## OAuth Token 來源

App 依下列優先順序讀取 OAuth Token：

1. 環境變數 `CLAUDE_CODE_OAUTH_TOKEN`
2. `~/.claude/.credentials.json`
3. macOS Keychain（服務名稱：`Claude Code-credentials`）

只要已登入 Claude Code，Token 會自動從 Keychain 或 credentials 檔案讀取，無需額外設定。

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
├── UsageService.swift       # API 呼叫與資料模型
├── TokenProvider.swift      # OAuth Token 讀取邏輯
├── UsageViewModel.swift     # 狀態管理與自動刷新
└── UsageRowView.swift       # 單列使用量 UI 元件
```

## API

使用 Anthropic OAuth Usage API：

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <OAuth Token>
anthropic-beta: oauth-2025-04-20
```

## 授權

MIT License — 詳見 [LICENSE](LICENSE)

## 作者

[SteveLo](https://github.com/sdpower)
