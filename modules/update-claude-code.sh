#!/usr/bin/env bash
set -euo pipefail

# Update script for local claude-code module
# Usage: ./modules/update-claude-code.sh [version]
# If no version specified, fetches latest from npm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/claude-code.nix"

# Get version (from arg or npm)
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    echo "Fetching latest version from npm..."
    VERSION=$(curl -s https://registry.npmjs.org/@anthropic-ai/claude-code/latest | grep -oP '"version"\s*:\s*"\K[^"]+')
fi

echo "Updating to version $VERSION"

# Download linux-x64 tarball and compute hash
TARBALL_URL="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${VERSION}.tgz"
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
