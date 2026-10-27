#!/usr/bin/env bash
set -euo pipefail

package_file="nix/pkgs/mailarchiver/default.nix"
deps_file="nix/pkgs/mailarchiver/deps.json"

version="$(${SED:-sed} -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$package_file" | head -n1)"

if [[ ! "$version" =~ ^[0-9]{4}\.[0-9]+$ ]]; then
  printf 'Unsupported MailArchiver version: %s\n' "$version" >&2
  exit 1
fi

archive_url="https://github.com/s1t5/mail-archiver/archive/${version}.tar.gz"
nix32_hash="$(nix-prefetch-url --unpack --type sha256 "$archive_url")"

NEW_HASH="$nix32_hash" perl -0pi -e \
  's/(sha256 = ")[^"]+(")/$1 . $ENV{NEW_HASH} . $2/se' \
  "$package_file"

fetch_deps="$(nix build .#mailarchiver.fetch-deps --no-link --print-out-paths)"
"$fetch_deps" "$deps_file"
