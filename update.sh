#!/usr/bin/env bash
# Regenerate sources.json with the latest Factory CLI version and per-system hashes.
# Pin a version with: ./update.sh 0.156.2
set -euo pipefail
cd "$(dirname "$0")"

ver="${1:-$(curl -fsSL https://app.factory.ai/cli | sed -n 's/^VER="\(.*\)"$/\1/p')}"
[ -n "$ver" ] || { echo "could not determine latest version" >&2; exit 1; }

base="https://downloads.factory.ai/factory-cli/releases/$ver"

# system -> CDN suffix
systems="x86_64-linux:linux/x64 aarch64-linux:linux/arm64 x86_64-darwin:darwin/x64 aarch64-darwin:darwin/arm64"

json=$(jq -n --arg version "$ver" '{version: $version, systems: {}}')
for entry in $systems; do
  sys="${entry%%:*}"; suffix="${entry#*:}"
  hex=$(curl -fsSL "$base/$suffix/droid.sha256")
  sri=$(nix hash convert --hash-algo sha256 "$hex")
  json=$(jq --arg s "$sys" --arg suf "$suffix" --arg h "$sri" \
    '.systems[$s] = {suffix: $suf, hash: $h}' <<<"$json")
done

printf '%s\n' "$json" > sources.json
echo "updated to $ver"
