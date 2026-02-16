#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.0.0"
  exit 1
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
DERIVED_DIR="${DIST_DIR}/DerivedData"
APP_PATH="${DERIVED_DIR}/Build/Products/Release/PortPeek.app"
ZIP_PATH="${DIST_DIR}/PortPeek.app.zip"

echo "==> Building PortPeek (Release, unsigned)"
xcodebuild \
  -project "${ROOT_DIR}/PortPeek.xcodeproj" \
  -scheme PortPeek \
  -configuration Release \
  -derivedDataPath "${DERIVED_DIR}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build >/dev/null

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Build output not found at: ${APP_PATH}"
  exit 1
fi

mkdir -p "${DIST_DIR}"
rm -f "${ZIP_PATH}"

echo "==> Creating zip"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

echo "==> Calculating SHA256"
SHA="$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"

echo
echo "Release artifacts:"
echo "  Version: ${VERSION}"
echo "  Zip: ${ZIP_PATH}"
echo "  SHA256: ${SHA}"
echo
echo "Use this SHA256 in your Homebrew cask."

