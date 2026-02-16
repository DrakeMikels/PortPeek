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
DERIVED_DIR="${DIST_DIR}/DerivedDataRelease"
APP_PATH="${DERIVED_DIR}/Build/Products/Release/PortPeek.app"
STAGING_DIR="${DIST_DIR}/dmg-staging"
DMG_PATH="${DIST_DIR}/PortPeek-${VERSION}.dmg"

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

echo "==> Preparing DMG staging folder"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Creating DMG"
rm -f "${DMG_PATH}"
hdiutil create \
  -volname "PortPeek" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}" >/dev/null

echo
echo "DMG created:"
echo "  ${DMG_PATH}"
echo
echo "Optional:"
echo "  Sign/notarize for wider macOS distribution."

