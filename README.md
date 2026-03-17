# CCMenuBar

A macOS Menu Bar app that displays real-time Claude Code API usage limits.

[繁體中文](README_ZH_TW.md)

## Features

- Displays four usage metrics: 5-hour, 7-day, 7-day Sonnet, and 7-day Opus
- Color-coded progress bars based on utilization (green / yellow / orange / red)
- Shows reset time for each metric
- Auto-refreshes every 5 minutes; manual refresh available via toolbar button
- Lives in the Menu Bar only — no Dock icon

## Requirements

- macOS 26.2+
- [Claude Code](https://claude.ai/download) installed and signed in

## OAuth Token Sources

The app reads the OAuth token in the following priority order:

1. Environment variable `CLAUDE_CODE_OAUTH_TOKEN`
2. `~/.claude/.credentials.json`
3. macOS Keychain (service name: `Claude Code-credentials`)

No manual configuration needed — the token is automatically discovered once you are signed in to Claude Code.

## Build

```bash
git clone <repo-url>
cd CCMenuBar
open CCMenuBar.xcodeproj
```

Select **Product → Run** (⌘R) in Xcode.

## Project Structure

```
CCMenuBar/
├── CCMenuBarApp.swift       # App entry point, MenuBarExtra configuration
├── ContentView.swift        # Popup window main UI
├── UsageService.swift       # API call and data models
├── TokenProvider.swift      # OAuth token resolution logic
├── UsageViewModel.swift     # State management and auto-refresh
└── UsageRowView.swift       # Single usage row UI component
```

## API

Uses the Anthropic OAuth Usage API:

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <OAuth Token>
anthropic-beta: oauth-2025-04-20
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

[SteveLo](https://github.com/sdpower)
