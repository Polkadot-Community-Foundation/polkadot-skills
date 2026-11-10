#!/usr/bin/env bash
# Check that every skill listed in upstream.json is an unmodified copy of the
# upstream release it records, that every skill folder is well formed, and that
# every manifest carries the release version.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

fail() { echo "check: $*" >&2; exit 1; }

for f in plugin.json .claude-plugin/plugin.json .claude-plugin/marketplace.json \
  .agents/plugins/marketplace.json upstream.json; do
  jq -e . "$f" > /dev/null || fail "$f is not valid JSON"
done

version="$(jq -r .version upstream.json)"
for got in \
  "plugin.json=$(jq -r .version plugin.json)" \
  ".claude-plugin/plugin.json=$(jq -r .version .claude-plugin/plugin.json)" \
  ".claude-plugin/marketplace.json=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)"; do
  [[ "${got#*=}" == "$version" ]] || fail "${got%%=*} has version ${got#*=}, upstream.json has $version"
done

for dir in skills/*/; do
  name="$(basename "$dir")"
  [[ -f "$dir/SKILL.md" ]] || fail "skills/$name has no SKILL.md"
  head -n 5 "$dir/SKILL.md" | grep -qx "name: $name" || fail "skills/$name/SKILL.md name does not match its folder"
done

repo="$(jq -r .repository upstream.json)"
tag="$(jq -r .tag upstream.json)"
commit="$(jq -r .commit upstream.json)"
path="$(jq -r .path upstream.json)"
mapfile -t listed < <(jq -r '.skills[]' upstream.json)
[[ ${#listed[@]} -gt 0 ]] || fail "upstream.json lists no skills"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -C "$work" init -q
git -C "$work" remote add origin "https://github.com/${repo}.git"
git -C "$work" sparse-checkout set "$path"
git -C "$work" fetch -q --depth 1 --filter=blob:none origin "refs/tags/${tag}:refs/tags/${tag}"
git -C "$work" -c advice.detachedHead=false checkout -q "refs/tags/${tag}"
[[ "$(git -C "$work" rev-parse 'HEAD^{commit}')" == "$commit" ]] || fail "$tag no longer points at $commit"

mapfile -t upstream < <(find "$work/$path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
[[ "$(printf '%s\n' "${listed[@]}")" == "$(printf '%s\n' "${upstream[@]}")" ]] \
  || fail "upstream.json skills do not match the folders at $tag:$path"
for name in "${listed[@]}"; do
  diff -r "$work/$path/$name" "skills/$name" > /dev/null || fail "skills/$name differs from $repo $tag"
done

echo "check: ok ($tag, ${#listed[@]} upstream skills, $(find skills -mindepth 1 -maxdepth 1 -type d | wc -l) total)"
