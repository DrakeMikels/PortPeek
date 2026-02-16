# PortPeek

PortPeek is a macOS menu bar app that monitors local development ports, shows which process is listening, and gives one-click actions to open endpoints or stop stuck processes.

## Project Description

Use this in your GitHub repository **About** field:

`macOS menu bar app for monitoring local development ports and managing listeners`

## What It Does

- Monitors a configurable list of local ports (defaults include 3000, 5173, 8080, 5432, etc.)
- Shows active listeners in the menu bar
- Lets you open a port in your default browser
- Lets you copy `host:port`
- Lets you terminate processes (SIGTERM/SIGKILL) when PID is available

## Requirements

- macOS 13.5+
- Xcode 15+

## Run Locally

1. Open `PortPeek.xcodeproj` in Xcode.
2. Select scheme `PortPeek`.
3. Run (`Cmd+R`).
4. Use the menu bar icon to inspect active ports.

## Settings

- `Settings...` lets you configure watched ports and refresh interval.
- Watched ports now support multiline input (6 rows): one port per line or comma-separated.

## Notes

- Some ports (for example `5000`) may be used by macOS services (for example ControlCenter). Those may not be browser endpoints.
- Browser access returning `403` means the service responded, but denied the request. It does not mean port detection is wrong.

## Homebrew Distribution (Cask)

PortPeek is a GUI app, so distribute it through a Homebrew **cask**.

### User Install

```bash
brew tap <owner>/<tap-repo>
brew install --cask portpeek
```

### Maintainer Release Flow

1. Push code to GitHub.
2. Create and push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

3. GitHub Actions builds release artifacts and uploads:
- `PortPeek.app.zip`
- `PortPeek-1.0.0.dmg`
- `SHA256SUMS.txt`

4. Generate cask file from SHA:

```bash
./scripts/generate_cask.sh 1.0.0 <owner> <source-repo> <sha256> /tmp/portpeek.rb
```

5. Copy generated cask into your tap repo at `Casks/portpeek.rb`, commit, and push.

### One-Command Local Brew Prep

If you already have a local tap repo clone:

```bash
./scripts/prepare_brew_release.sh 1.0.0 <owner> <source-repo> <path-to-homebrew-tap>
```

This will:
- build `dist/PortPeek.app.zip`
- compute SHA256
- write `Casks/portpeek.rb` into your tap repo

### Manual Packaging (Local)

Build zip for releases:

```bash
./scripts/package_release.sh 1.0.0
```

Build DMG:

```bash
./scripts/package_dmg.sh 1.0.0
```

## Repository Layout

- `AppDelegate.swift` - app lifecycle and menu orchestration
- `PortScanner.swift` - listener detection
- `MenuBuilder.swift` - dynamic menu UI
- `PortPeek/SettingsWindowController.swift` - settings window UI
- `scripts/package_release.sh` - release zip + SHA helper
- `scripts/package_dmg.sh` - release DMG helper
- `scripts/generate_cask.sh` - generate Homebrew cask file from version/SHA
- `packaging/homebrew/portpeek.rb.template` - cask template
- `.github/workflows/release.yml` - GitHub tag release automation
