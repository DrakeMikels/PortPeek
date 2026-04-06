# Homebrew Cask Maintainer Notes

PortPeek is distributed as a Homebrew cask via a tap repository.

## User Install

```bash
brew tap DrakeMikels/homebrew-tap
brew install --cask portpeek
```

## Release Flow

1. Push a version tag — GitHub Actions builds, signs, notarizes, and publishes the release assets automatically.

```bash
git tag v1.0.0
git push origin v1.0.0
```

2. Get the SHA256 from the published `SHA256SUMS.txt` on the release page, then generate the cask file:

```bash
./scripts/generate_cask.sh 1.0.0 DrakeMikels PortPeek <sha256> /tmp/portpeek.rb
```

3. Copy the generated file into the tap repo and push:

```
homebrew-tap/Casks/portpeek.rb
```

Or use the one-command helper if you have the tap repo cloned locally:

```bash
./scripts/prepare_brew_release.sh 1.0.0 DrakeMikels PortPeek <path-to-homebrew-tap>
```

## Required GitHub Secrets

Configure these in Settings → Secrets and variables → Actions before your first release:

| Secret | Description |
|---|---|
| `MACOS_CERTIFICATE_P12_BASE64` | Base64-encoded Developer ID Application `.p12` — run `base64 -i DeveloperID_Application.p12 \| pbcopy` |
| `MACOS_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `MACOS_KEYCHAIN_PASSWORD` | Any strong temporary password for the CI keychain |
| `MACOS_SIGNING_IDENTITY` | Full signing identity, e.g. `Developer ID Application: Your Name (TEAMID)` |
| `NOTARY_KEY_ID` | App Store Connect API key ID |
| `NOTARY_ISSUER_ID` | App Store Connect issuer ID |
| `NOTARY_API_KEY_P8` | Full contents of `AuthKey_<KEY_ID>.p8` |

## Tap Repo Layout

The tap repository (`homebrew-tap`) should contain:

```
Casks/portpeek.rb
```
