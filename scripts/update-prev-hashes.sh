#!/usr/bin/env bash
set -euo pipefail

package_file="nix/pkgs/prev/default.nix"

version="$(${SED:-sed} -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$package_file" | head -n1)"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Unsupported Prev version: %s\n' "$version" >&2
  exit 1
fi

update_hash() {
  local system="$1"
  local suffix="$2"
  local url="https://github.com/scrambletools/prev/releases/download/v${version}/prev-${version}-${suffix}-linux.tar.gz"
  local nix32_hash
  local sri_hash

  nix32_hash="$(nix-prefetch-url --type sha256 "$url")"
  sri_hash="$(nix hash convert --hash-algo sha256 --from nix32 --to sri "$nix32_hash")"

  NEW_HASH="$sri_hash" SYSTEM="$system" perl -0pi -e \
    's/("\Q$ENV{SYSTEM}\E"\s*=\s*\{\s*hash = ")[^"]+(")/$1 . $ENV{NEW_HASH} . $2/se' \
    "$package_file"
}

update_hash "x86_64-linux" "x86_64"
update_hash "aarch64-linux" "aarch64"
