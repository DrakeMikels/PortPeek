# Homebrew Cask Notes

PortPeek should be distributed as a Homebrew cask.

## Tap Repo Layout

Use a separate tap repository, typically:

- `homebrew-tap`

Inside that repo:

- `Casks/portpeek.rb`

## Generate Cask

From the PortPeek source repo:

```bash
./scripts/generate_cask.sh 1.0.0 <owner> <source-repo> <sha256> /tmp/portpeek.rb
```

Then copy `/tmp/portpeek.rb` into your tap repo as `Casks/portpeek.rb`.

## User Install

```bash
brew tap <owner>/tap
brew install --cask portpeek
```

