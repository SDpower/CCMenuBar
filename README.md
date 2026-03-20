# CCMenuBar

A macOS Menu Bar app that displays real-time Claude Code rate limit status by executing the `claude` CLI.

[繁體中文](README_ZH_TW.md)

## Features

- Displays current rate limit status: **Available** or **Rate Limited**
- Dynamic gauge icon in the Menu Bar — needle position reflects time elapsed in the 5-hour window
- Icon and text turn **red** when rate-limited, **orange** when using overage quota
- Shows time remaining until the rate limit resets (relative format, e.g. "in 2 hours")
- Auto-refreshes every 5 minutes; manual refresh available via toolbar button
- When CLI is not found, shows an installation prompt with a direct link
- Lives in the Menu Bar only — no Dock icon
- Supports 12 languages

## Requirements

- macOS 15.0+
- [Claude Code](https://claude.ai/download) installed and signed in

## How It Works

CCMenuBar runs the `claude` CLI with `--verbose --output-format json` to obtain a `rate_limit_event` from the JSON output, then parses the rate limit status and reset time. No API tokens or network requests are made directly by the app.

The CLI is discovered in the following paths (in order):

1. `~/.local/bin/claude` (native install)
2. `~/.claude/bin/claude`
3. `/opt/homebrew/bin/claude`
4. `/usr/local/bin/claude`

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
├── UsageService.swift       # CLI execution, JSON parsing, and data models
├── UsageViewModel.swift     # State management, auto-refresh, gauge logic
└── UsageRowView.swift       # Rate limit status row UI component
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

[SteveLo](https://github.com/sdpower)
