#!/usr/bin/env bash
# Rewrite release.json from the npm registry (dist-tag "latest").
set -euo pipefail
cd "$(dirname "$0")"

registry=https://registry.npmjs.org
version=$(curl -fsS "$registry/@polar-sh/cli/latest" | jq -r .version)

if [[ -f release.json && $(jq -r .version release.json) == "$version" ]]; then
  echo "up to date: $version"
  exit 0
fi

# Nix system -> the npm package that holds its binary.
declare -A packages=(
  [x86_64-linux]=cli-linux-x64
  [aarch64-linux]=cli-linux-arm64
)

platforms='{}'
for system in "${!packages[@]}"; do
  # npm's dist.integrity is already an SRI hash (sha512-...), which fetchurl accepts.
  dist=$(curl -fsS "$registry/@polar-sh/${packages[$system]}/$version" | jq .dist)
  platforms=$(jq --arg s "$system" --argjson d "$dist" \
    '. + {($s): {url: $d.tarball, hash: $d.integrity}}' <<<"$platforms")
done

jq -n --arg v "$version" --argjson p "$platforms" '{version: $v, platforms: $p}' > release.json
echo "updated to $version"
