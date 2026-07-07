#!/bin/zsh
# PostToolUse(Write|Edit|MultiEdit): open an edited Markdown file in the
# user's configured Chromium browser. Config: ${CLAUDE_PLUGIN_DATA}/config.json.
# Always exits 0 so a failure never blocks the edit.
emulate -L zsh
setopt extendedglob

input="$(cat)"
p="$(print -r -- "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[[ -n "$p" ]] || exit 0

# Markdown only.
case "$p" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

config="${CLAUDE_PLUGIN_DATA}/config.json"
[[ -f "$config" ]] || exit 0

browser="$(jq -r '.browser // empty' "$config" 2>/dev/null)"
[[ -n "$browser" ]] || exit 0
space="$(jq -r '.space // empty' "$config" 2>/dev/null)"

# Scope: if any patterns configured, the path must match at least one.
scope_count="$(jq -r '(.scope // []) | length' "$config" 2>/dev/null || echo 0)"
if [[ "$scope_count" -gt 0 ]]; then
  matched=0
  while IFS= read -r pattern; do
    [[ -n "$pattern" ]] || continue
    # In [[ ]] matching, * spans '/', but a literal '/' in the pattern still
    # requires a path separator — so a leading **/ requires at least one
    # directory segment and will NOT match a file directly in that folder.
    # Patterns must include a direct-child variant (e.g. DIR/*.md) to also
    # match files directly in a folder.
    if [[ "$p" == ${~pattern} ]]; then matched=1; break; fi
  done < <(jq -r '.scope[]' "$config" 2>/dev/null)
  [[ "$matched" -eq 1 ]] || exit 0
fi

osascript "${CLAUDE_PLUGIN_ROOT}/bin/open-in-browser.applescript" \
  "file://$p" "$browser" "$space" >/dev/null 2>&1
exit 0
