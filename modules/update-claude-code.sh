#!/usr/bin/env bash
set -euo pipefail

# Update script for local claude-code module
# Usage: ./update-claude-code.sh [version]
# If no version specified, fetches latest from npm
#
# Run with nix-shell if npm/node not in PATH:
#   nix-shell -p nodejs curl --run "./update-claude-code.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/claude-code.nix"
LOCK_FILE="$SCRIPT_DIR/package-lock.json"

# Get version (from arg or npm)
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    echo "Fetching latest version from npm..."
    VERSION=$(npm view @anthropic-ai/claude-code version)
fi

echo "Updating to version $VERSION"

# Create temp directory
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Download and extract tarball
echo "Downloading tarball..."
TARBALL_URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${VERSION}.tgz"
curl -sL "$TARBALL_URL" -o "$TMPDIR/claude-code.tgz"

# Compute source hash
echo "Computing source hash..."
mkdir -p "$TMPDIR/src"
tar -xzf "$TMPDIR/claude-code.tgz" -C "$TMPDIR/src" --strip-components=1
SRC_HASH=$(nix hash path "$TMPDIR/src")
echo "Source hash: $SRC_HASH"

# Generate package-lock.json
echo "Generating package-lock.json..."
cd "$TMPDIR/src"
npm install --package-lock-only --ignore-scripts 2>/dev/null
cp package-lock.json "$LOCK_FILE"
echo "Updated $LOCK_FILE"

# Update version and hash in nix file
echo "Updating $NIX_FILE..."
sed -i "s|version = \"[^\"]*\";|version = \"$VERSION\";|" "$NIX_FILE"
sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$SRC_HASH\";|" "$NIX_FILE"

# Set npmDepsHash to empty so we can compute it
sed -i 's|npmDepsHash = "sha256-[^"]*";|npmDepsHash = "";|' "$NIX_FILE"

echo ""
echo "Version and source hash updated. Now computing npmDepsHash..."
echo "This will build the package with an empty hash to get the correct one."
echo ""

# Build to get the correct npmDepsHash
cd "$SCRIPT_DIR/.."
BUILD_OUTPUT=$(nix-build --no-out-link -E "with import <nixpkgs> {}; callPackage ./modules/claude-code.nix {}" 2>&1 || true)

# Extract the hash from the build output
NPM_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got:\s*\Ksha256-[A-Za-z0-9+/=]+' | head -1 || true)

if [[ -n "$NPM_HASH" ]]; then
    echo "Got npmDepsHash: $NPM_HASH"
    sed -i "s|npmDepsHash = \"\";|npmDepsHash = \"$NPM_HASH\";|" "$NIX_FILE"
    echo ""
    echo "Done! All hashes updated. Verifying build..."
    nix-build --no-out-link -E "with import <nixpkgs> {}; callPackage ./modules/claude-code.nix {}" && echo "Build successful!"
else
    echo "Could not extract npmDepsHash automatically."
    echo "Build output:"
    echo "$BUILD_OUTPUT" | tail -20
    echo ""
    echo "Please manually set npmDepsHash in $NIX_FILE"
fi
