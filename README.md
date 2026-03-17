# CCMenuBar

A macOS Menu Bar app that displays real-time Claude Code API usage limits.

[繁體中文](README_ZH_TW.md)

## Features

- Displays usage metrics: 5-hour, 7-day, 7-day Sonnet, 7-day Opus, and 7-day OAuth Apps
- Dynamic gauge icon in the Menu Bar — needle position reflects current utilization
- Configurable Menu Bar display: choose which metrics appear as text alongside the icon
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

## Security Note

On first launch, macOS may display a dialog asking whether to allow CCMenuBar to access Keychain items created by Claude Code:

> *"CCMenuBar wants to access the item 'Claude Code-credentials' in your keychain."*

This is expected behavior. The app reads the OAuth token stored by Claude Code in the system Keychain to authenticate API requests. Click **Allow** (or **Always Allow** to avoid repeated prompts). The app does not store, transmit, or modify any Keychain data beyond reading the token.

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
├── UsageViewModel.swift     # State management, auto-refresh, and Menu Bar display settings
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
