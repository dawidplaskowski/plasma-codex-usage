# Codex Usage Widget

A KDE Plasma 6 widget that displays your OpenAI Codex CLI usage statistics in the taskbar.

> Unofficial project — not affiliated with or endorsed by OpenAI.

![Popup](screenshots/popup.png)

## Features

- **Current limits**: Asks chatgpt.com with the token Codex CLI already stored, the same request as its `/status`; when that token has expired, falls back to the rate-limit snapshots in Codex CLI session logs (`~/.codex/sessions/`) — no API keys
  ![Panel](screenshots/panel.png)
- **Weekly & Secondary Limits**: Usage percentages with reset countdowns, straight from the Codex CLI's own `rate_limits` data
- **Time-Proportional Coloring**: Colors based on elapsed time vs usage ratio (configurable, can switch to fixed thresholds)
- **Card Popup**: Modern card-based popup with configurable card order and visibility
  - Account info (email + plan from `auth.json`), usage ring, token stats (input/output/cached/reasoning), 7-day trend chart, quick links
- **Classic Popup**: Traditional layout with progress bars (switchable in settings)
- **Panel Styles**: Icon with usage badge, rings, or text — with a choice of ChatGPT or OpenAI icon
- **Desktop Notifications**: Alerts when usage crosses thresholds
- **Update Checker**: Dot on the panel icon when a new Codex CLI version is available
- **Process Visibility**: Hide widget or usage when Codex is not running
- **Configurable Refresh**: Adjustable polling interval
- **Local Cache**: Remembers last data on restart
- **Stale Detection**: Widget dims when data is outdated
- **Configurable Background Opacity**: Adjustable transparency for desktop placement
- **15 Languages**: EN, HU, DE, FR, ES, IT, PT, RU, PL, NL, TR, JA, KO, ZH-CN, ZH-TW
- **No Dependencies**: Pure QML + POSIX shell, no Python or external tools required

## Requirements

- KDE Plasma 6.0 or later
- [OpenAI Codex CLI](https://github.com/openai/codex) installed and logged in

## Installation

### Manual Installation

```bash
kpackagetool6 -t Plasma/Applet -i codex-usage-widget.plasmoid
```

### From Source

```bash
git clone https://github.com/izll/plasma-codex-usage.git
cd plasma-codex-usage
./install.sh
```

## Usage

1. Make sure you're logged in to Codex CLI (run `codex` in a terminal at least once)
2. Add the widget to your panel: right-click panel → "Add Widgets..." → search for "Codex Usage"
3. The widget fetches the current limits (or reads the latest snapshot from your local session logs) and refreshes periodically

## How It Works

The widget asks `chatgpt.com/backend-api/wham/usage` for the current limits, using the access token Codex CLI keeps in `~/.codex/auth.json`. It never refreshes that token itself (that would rotate it behind the CLI's back), so after a few days without Codex the request fails and the widget falls back to the `rate_limits` snapshot the CLI writes into its session logs (`~/.codex/sessions/*.jsonl`) with every request. Such a snapshot is only as fresh as the last Codex run: windows whose reset time has passed show 0%, the footer shows the snapshot's age, and the widget dims once it is stale. Account email and plan are read locally from `~/.codex/auth.json`.

## Credits

Based on [Claude Usage Widget](https://github.com/izll/plasma-claude-usage) and the work of its contributors.

## Related

- [Claude Usage Widget](https://github.com/izll/plasma-claude-usage) — the same concept for Claude Code

## License

GPL-3.0-or-later
