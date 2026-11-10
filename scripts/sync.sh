#!/usr/bin/env bash
# Mirror the agent skills from a paritytech/product-sdk release tag into skills/,
# then stamp the release version and source into the manifests and README.
# Only the skill folders listed in upstream.json are replaced; other folders in
# skills/ are left alone.
#
# Usage: scripts/sync.sh [tag]   (default: newest @parity/product-sdk@X.Y.Z tag)
set -euo pipefail

UPSTREAM_REPO="paritytech/product-sdk"
UPSTREAM_URL="https://github.com/${UPSTREAM_REPO}.git"
UPSTREAM_PATH="product-sdk/skills"
TAG_PREFIX="@parity/product-sdk@"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

tag="${1:-}"
if [[ -z "$tag" ]]; then
  tag="$(git ls-remote --tags --refs "$UPSTREAM_URL" "refs/tags/${TAG_PREFIX}*" \
    | awk '{sub("refs/tags/", "", $2); print $2}' \
    | grep -E "^${TAG_PREFIX//./\\.}[0-9]+\.[0-9]+\.[0-9]+$" \
    | sort -t@ -k3 -V | tail -n1)"
fi
[[ "$tag" == "${TAG_PREFIX}"* ]] || { echo "not a product-sdk release tag: '$tag'" >&2; exit 1; }
version="${tag#"$TAG_PREFIX"}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

git -C "$work" init -q
git -C "$work" remote add origin "$UPSTREAM_URL"
git -C "$work" sparse-checkout set "$UPSTREAM_PATH"
git -C "$work" fetch -q --depth 1 --filter=blob:none origin "refs/tags/${tag}:refs/tags/${tag}"
git -C "$work" -c advice.detachedHead=false checkout -q "refs/tags/${tag}"
commit="$(git -C "$work" rev-parse 'HEAD^{commit}')"

src="$work/$UPSTREAM_PATH"
[[ -d "$src" ]] || { echo "$UPSTREAM_PATH missing at $tag" >&2; exit 1; }

mapfile -t new_skills < <(find "$src" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
[[ ${#new_skills[@]} -gt 0 ]] || { echo "no skills found at $tag" >&2; exit 1; }
old_skills=()
if [[ -f upstream.json ]]; then
  mapfile -t old_skills < <(jq -r '.skills[]' upstream.json)
fi

mkdir -p skills
for name in "${new_skills[@]}"; do
  if [[ -e "skills/$name" ]] && ! printf '%s\n' "${old_skills[@]}" | grep -qx "$name"; then
    echo "skills/$name exists and is not from upstream; refusing to overwrite it" >&2
    exit 1
  fi
done
for name in "${old_skills[@]}"; do
  rm -rf "skills/${name:?}"
done
for name in "${new_skills[@]}"; do
  cp -R "$src/$name" "skills/$name"
done

jq -n --arg repo "$UPSTREAM_REPO" --arg tag "$tag" --arg commit "$commit" \
  --arg path "$UPSTREAM_PATH" --arg version "$version" \
  --args '{repository: $repo, tag: $tag, commit: $commit, path: $path, version: $version, skills: $ARGS.positional}' \
  "${new_skills[@]}" > upstream.json

set_version() {
  local file="$1" path="$2" tmp
  tmp="$(mktemp)"
  jq --arg v "$version" "${path} = \$v" "$file" > "$tmp"
  mv "$tmp" "$file"
}
set_version plugin.json .version
set_version .claude-plugin/plugin.json .version
set_version .claude-plugin/marketplace.json '.plugins[0].version'

# Regenerate the upstream skills list between the README markers.
list="$(mktemp)"
{
  echo "<!-- skills:start -->"
  echo "From [\`${tag}\`](https://github.com/${UPSTREAM_REPO}/tree/${commit}/${UPSTREAM_PATH}):"
  echo
  for name in "${new_skills[@]}"; do
    echo "- [\`${name}\`](skills/${name}/SKILL.md)"
  done
  echo "<!-- skills:end -->"
} > "$list"
awk -v list="$list" '
  /<!-- skills:start -->/ { while ((getline line < list) > 0) print line; skip = 1; next }
  /<!-- skills:end -->/   { skip = 0; next }
  !skip { print }
' README.md > README.md.tmp
mv README.md.tmp README.md
rm -f "$list"

echo "synced ${#new_skills[@]} skills from ${tag} (${commit})"
