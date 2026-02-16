# Homebrew Cask Maintainer Notes

PortPeek should be distributed as a Homebrew cask.

## Public Distribution Requirements

To avoid macOS Gatekeeper "app is damaged" warnings for users, releases must be:
- signed with **Developer ID Application**
- notarized with Apple Notary service
- stapled before publishing assets

The release workflow is configured to do this automatically.

### Required GitHub Secrets

Add these repo secrets in GitHub Settings -> Secrets and variables -> Actions:

- `MACOS_CERTIFICATE_P12_BASE64`
: base64 of your Developer ID Application `.p12` file
- `MACOS_CERTIFICATE_PASSWORD`
: password used when exporting the `.p12`
- `MACOS_KEYCHAIN_PASSWORD`
: any strong temporary password for the CI keychain
- `MACOS_SIGNING_IDENTITY`
: full signing identity string, e.g. `Developer ID Application: Your Name (TEAMID)`
- `NOTARY_KEY_ID`
: App Store Connect API key ID
- `NOTARY_ISSUER_ID`
: App Store Connect issuer ID
- `NOTARY_API_KEY_P8`
: full contents of `AuthKey_<KEY_ID>.p8`

Example to produce `MACOS_CERTIFICATE_P12_BASE64` locally:

```bash
base64 -i DeveloperID_Application.p12 | pbcopy
```

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
