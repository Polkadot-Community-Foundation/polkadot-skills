#!/usr/bin/env bash
# Check that every skill listed in upstream.json is an unmodified copy of the
# upstream release it records, that every skill folder is well formed, that
# every manifest carries the release version, and that the plugin folder holds
# only file types the Claude plugin directory accepts.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

PLUGIN_DIR="plugins/polkadot-skills"
SKILLS_DIR="${PLUGIN_DIR}/skills"

fail() { echo "check: $*" >&2; exit 1; }

for f in "$PLUGIN_DIR/plugin.json" "$PLUGIN_DIR/.claude-plugin/plugin.json" \
  .claude-plugin/marketplace.json .agents/plugins/marketplace.json skills.sh.json upstream.json; do
  jq -e . "$f" > /dev/null || fail "$f is not valid JSON"
done

version="$(jq -r .version upstream.json)"
for got in \
  "$PLUGIN_DIR/plugin.json=$(jq -r .version "$PLUGIN_DIR/plugin.json")" \
  "$PLUGIN_DIR/.claude-plugin/plugin.json=$(jq -r .version "$PLUGIN_DIR/.claude-plugin/plugin.json")" \
  ".claude-plugin/marketplace.json=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)"; do
  [[ "${got#*=}" == "$version" ]] || fail "${got%%=*} has version ${got#*=}, upstream.json has $version"
done

for dir in "$SKILLS_DIR"/*/; do
  name="$(basename "$dir")"
  [[ -f "$dir/SKILL.md" ]] || fail "$SKILLS_DIR/$name has no SKILL.md"
  head -n 5 "$dir/SKILL.md" | grep -qx "name: $name" || fail "$SKILLS_DIR/$name/SKILL.md name does not match its folder"
done

# The Claude plugin directory accepts Markdown, text, JSON, YAML and PNG, JPEG,
# GIF, WebP or ICO images, rejects anything starting with #!, and requires UTF-8
# text without NUL bytes.
while IFS= read -r -d '' f; do
  case "$f" in
    *.md | *.txt | *.json | *.yml | *.yaml | */LICENSE | */NOTICE) ;;
    *.png | *.jpg | *.jpeg | *.gif | *.webp | *.ico) continue ;;
    *) fail "$f: file type not accepted by the Claude plugin directory" ;;
  esac
  [[ "$(head -c 2 "$f")" != "#!" ]] || fail "$f starts with #!"
  iconv -f UTF-8 -t UTF-8 "$f" > /dev/null 2>&1 || fail "$f is not UTF-8"
  [[ "$(tr -d '\000' < "$f" | wc -c)" == "$(wc -c < "$f")" ]] || fail "$f contains a NUL byte"
done < <(find "$PLUGIN_DIR" -type f -print0)

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
  diff -r "$work/$path/$name" "$SKILLS_DIR/$name" > /dev/null || fail "$SKILLS_DIR/$name differs from $repo $tag"
done

echo "check: ok ($tag, ${#listed[@]} upstream skills, $(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l) total)"
