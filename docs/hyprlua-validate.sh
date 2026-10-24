#!/bin/bash
# Stage the hypr tree, render chezmoi templates, and parse it with Hyprland.
# Usage: docs/hyprlua-validate.sh <repo-root>
set -uo pipefail
repo=${1:?repo root}
stage=/tmp/opencode/hyprlua-stage
rm -rf "$stage"
cp -r "$repo/dot_config/hypr" "$stage"
cd "$stage" || exit 1

# Render templates exactly the way chezmoi would.
find . -name '*.tmpl' -print0 | while IFS= read -r -d '' f; do
  chezmoi execute-template < "$f" > "${f%.tmpl}" || { echo "RENDER FAIL $f"; exit 1; }
  rm "$f"
done

# Lua files must not reference the hyprlang originals.
echo "--- lua modules present:"
find . -name '*.lua' | sort | sed 's/^/  /'

echo "--- verify-config:"
hyprland -c "$stage/hyprland.lua" --verify-config > /tmp/opencode/hyprlua-verify.log 2>&1
rc=$?
sed -n '/Config parsing result/,$p' /tmp/opencode/hyprlua-verify.log | tail -20
echo "EXIT=$rc"
exit $rc
