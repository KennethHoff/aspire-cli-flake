#!/usr/bin/env bash
set -euo pipefail

CHANNELS=("${@:-stable staging dev}")
if [[ $# -eq 0 ]]; then
  CHANNELS=(stable staging dev)
fi

resolve_url() {
  case "$1" in
    stable)  echo "https://aka.ms/dotnet/9/aspire/ga/daily/aspire-cli-linux-x64.tar.gz" ;;
    staging) echo "https://aka.ms/dotnet/9/aspire/rc/daily/aspire-cli-linux-x64.tar.gz" ;;
    dev)     echo "https://aka.ms/dotnet/9/aspire/daily/aspire-cli-linux-x64.tar.gz" ;;
    *)       echo "Unknown channel: $1" >&2; exit 1 ;;
  esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$SCRIPT_DIR/versions.nix"

for channel in "${CHANNELS[@]}"; do
  echo "=== Updating $channel channel ==="

  redirect_url=$(resolve_url "$channel")
  echo "Resolving latest version from $channel channel..."
  tarball_url=$(curl -sL -o /dev/null -w '%{url_effective}\n' "$redirect_url")
  version=$(echo "$tarball_url" | sed -n 's#^.*/public/aspire/\([^/]*\)/.*#\1#p')

  if [[ -z "$version" ]]; then
    echo "Failed to resolve version for $channel" >&2
    exit 1
  fi

  echo "Found version: $version"
  echo "Tarball URL: $tarball_url"

  current_version=$(sed -n "/^  $channel = {/,/};/{s/.*version = \"\([^\"]*\)\".*/\1/p;}" "$VERSIONS_FILE")
  if [[ "$version" == "$current_version" ]]; then
    echo "$channel is already up to date."
    continue
  fi

  echo "Fetching hash for $version..."
  hash=$(nix-prefetch-url --type sha512 "$tarball_url" 2>/dev/null | xargs nix hash convert --hash-algo sha512 --to sri)

  echo "New hash: $hash"

  # Update the version, url, and hash for this channel in versions.nix
  sed -i "/^  $channel = {/,/};/{
    s|version = \"[^\"]*\"|version = \"$version\"|
    s|url = \"[^\"]*\"|url = \"$tarball_url\"|
    s|hash = \"[^\"]*\"|hash = \"$hash\"|
  }" "$VERSIONS_FILE"

  echo "Updated $channel to version $version"
done

echo "Done."
