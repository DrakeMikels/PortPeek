#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <version> <github_owner> <source_repo> <tap_repo_path>"
  echo "Example: $0 1.0.0 mike PortPeek ../homebrew-tap"
  exit 1
fi

VERSION="$1"
OWNER="$2"
SOURCE_REPO="$3"
TAP_REPO_PATH="$4"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_PATH="${ROOT_DIR}/dist/PortPeek.app.zip"
TAP_CASK_PATH="${TAP_REPO_PATH}/Casks/portpeek.rb"

echo "==> Packaging zip"
"${ROOT_DIR}/scripts/package_release.sh" "${VERSION}"

if [[ ! -f "${ZIP_PATH}" ]]; then
  echo "Missing zip artifact: ${ZIP_PATH}"
  exit 1
fi

echo "==> Calculating SHA256"
SHA="$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"

echo "==> Writing cask to tap repo"
mkdir -p "${TAP_REPO_PATH}/Casks"
"${ROOT_DIR}/scripts/generate_cask.sh" "${VERSION}" "${OWNER}" "${SOURCE_REPO}" "${SHA}" "${TAP_CASK_PATH}"

echo
echo "Ready:"
echo "  Zip: ${ZIP_PATH}"
echo "  SHA256: ${SHA}"
echo "  Cask: ${TAP_CASK_PATH}"
echo
echo "Next:"
echo "  1) Upload ${ZIP_PATH} to GitHub release tag v${VERSION} in ${OWNER}/${SOURCE_REPO}"
echo "  2) Commit/push cask changes in your tap repo"

