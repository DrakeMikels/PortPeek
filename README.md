# PortPeek

A macOS menu bar app for monitoring local development ports. See what's running, open it in your browser, or stop stuck listeners without leaving the menu bar.

## Install

### Homebrew

```bash
brew install --cask DrakeMikels/tap/portpeek
```

### Direct Download

1. Download `PortPeek-*.dmg` from the [latest release](../../releases/latest)
2. Open the DMG and drag PortPeek to `/Applications`
3. Launch PortPeek. The `⚡︎` icon appears in your menu bar

> **macOS 13.5 or later required.**
> Release builds are signed and notarized.

## What It Does

Click the `⚡︎` menu bar icon to see active listeners on your watched ports. Each entry shows the port number and process name. Open an entry to see:

- **Open in Browser** — opens `http://localhost:<port>` in your default browser
- **Copy Host:Port** — copies `localhost:<port>` to your clipboard
- **Kill Process (SIGTERM)** — gracefully stops the process
- **Force Kill (SIGKILL)** — immediately terminates it if SIGTERM didn't work

The menu also shows PID, user, and protocol (TCP/UDP) for each active port.

The menu refreshes automatically in the background and also rescans every time you open it.

## Default Watched Ports

3000, 3001, 4000, 5000, 5173, 5432, 6379, 8000, 8080, 9200, 15672, 27017

These cover common dev servers, databases, and message brokers (Vite, Rails, Django, Postgres, Redis, Elasticsearch, RabbitMQ, MongoDB).

## Settings

Open **Settings…** from the menu (or press `,`) to configure:

- **Watched Ports** — the list of ports to scan. Enter one per line or comma-separated.
- **Refresh Interval** — how often to scan in the background (seconds). Default is 5.
- **Show Inactive Ports** — when enabled, ports you're watching that have nothing running are shown in the menu as greyed-out entries.

Use **Reset to Defaults** to restore the original port list and interval.

## Notes

- Port 5000 is used by macOS ControlCenter on some systems. It will show as active even when you have nothing running on it.
- A `403` response from "Open in Browser" means the service is running and responded — it just denied the request. Port detection is working correctly.
- PortPeek is a menu bar app. It does not open a main window during normal use.

---

## Build From Source

**Requirements:** macOS 13.5+, Xcode 15+

1. Clone the repo and open `PortPeek.xcodeproj`
2. Select the `PortPeek` scheme and press `Cmd+R`

## Contributing

Issues and pull requests are welcome.

## Project Layout

| File | Purpose |
|---|---|
| `AppDelegate.swift` | App lifecycle, menu orchestration, timer |
| `PortScanner.swift` | Port listener detection |
| `MenuBuilder.swift` | Dynamic menu UI |
| `PortPeek/SettingsWindowController.swift` | Settings window |
| `Preferences.swift` | UserDefaults persistence |
| `PortInfo.swift` | Port data model |
| `ProcessKiller.swift` | SIGTERM/SIGKILL implementation |
| `scripts/` | Local packaging helpers |

## Maintainer Notes

Packaging, signing, notarization, and Homebrew tap notes live in [`packaging/homebrew/README.md`](packaging/homebrew/README.md).
