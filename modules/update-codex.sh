#!/usr/bin/env bash
set -euo pipefail

# Update script for local codex module
# Usage: ./modules/update-codex.sh [version]
# If no version specified, fetches latest from npm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/codex.nix"

# Get version (from arg or npm)
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    echo "Fetching latest version from npm..."
    VERSION=$(curl -s https://registry.npmjs.org/@openai/codex/latest | grep -oP '"version"\s*:\s*"\K[^"]+')
fi

echo "Updating to version $VERSION"

# The platform builds are published as versions of @openai/codex itself,
# suffixed with the platform (e.g. 0.154.0-linux-x64).
TARBALL_URL="https://registry.npmjs.org/@openai/codex/-/codex-${VERSION}-linux-x64.tgz"
echo "Downloading $TARBALL_URL..."

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

curl -sL "$TARBALL_URL" -o "$TMPDIR/pkg.tgz"

echo "Computing source hash..."
mkdir -p "$TMPDIR/src"
tar -xzf "$TMPDIR/pkg.tgz" -C "$TMPDIR/src" --strip-components=1
SRC_HASH=$(nix hash path "$TMPDIR/src")
echo "Source hash: $SRC_HASH"

# Update version and hash in nix file
sed -i "s|version = \"[^\"]*\";|version = \"$VERSION\";|" "$NIX_FILE"
sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$SRC_HASH\";|" "$NIX_FILE"

echo "Done! Updated $NIX_FILE"
