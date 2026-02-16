#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <version> <github_owner> <source_repo> <sha256> [output_path]"
  echo "Example: $0 1.0.0 mike PortPeek abc123... /tmp/portpeek.rb"
  exit 1
fi

VERSION="$1"
OWNER="$2"
SOURCE_REPO="$3"
SHA256="$4"
OUTPUT_PATH="${5:-packaging/homebrew/portpeek.rb}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"

cat > "${OUTPUT_PATH}" <<EOF
cask "portpeek" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/${OWNER}/${SOURCE_REPO}/releases/download/v#{version}/PortPeek.app.zip"
  name "PortPeek"
  desc "Menu bar utility for monitoring local development ports"
  homepage "https://github.com/${OWNER}/${SOURCE_REPO}"

  depends_on macos: ">= :ventura"
  app "PortPeek.app"
end
EOF

echo "Cask written to: ${OUTPUT_PATH}"

