# Homebrew Cask Maintainer Notes

PortPeek should be distributed as a Homebrew cask.

## Project Description

Suggested GitHub repository About text:

`macOS menu bar app for monitoring local development ports and managing listeners`

## User Install

```bash
brew tap <owner>/<tap-repo>
brew install --cask portpeek
```

## Maintainer Release Flow

1. Push code to GitHub.
2. Create and push a version tag.

```bash
git tag v1.0.0
git push origin v1.0.0
```

3. GitHub Actions builds and uploads release assets:
- `PortPeek.app.zip`
- `PortPeek-1.0.0.dmg`
- `SHA256SUMS.txt`

4. Generate cask file from SHA:

```bash
./scripts/generate_cask.sh 1.0.0 <owner> <source-repo> <sha256> /tmp/portpeek.rb
```

5. Copy generated file into your tap repo:
- `Casks/portpeek.rb`

6. Commit and push the tap repo.

## One-Command Local Brew Prep

If you already have a local tap repo clone:

```bash
./scripts/prepare_brew_release.sh 1.0.0 <owner> <source-repo> <path-to-homebrew-tap>
```

This will:
- build `dist/PortPeek.app.zip`
- compute SHA256
- write `Casks/portpeek.rb` in your tap repo

## Manual Packaging

Build release zip:

```bash
./scripts/package_release.sh 1.0.0
```

Build DMG:

```bash
./scripts/package_dmg.sh 1.0.0
```

## Tap Repo Layout

Use a separate tap repository, commonly named:

- `homebrew-tap`

Inside that repo:

- `Casks/portpeek.rb`
