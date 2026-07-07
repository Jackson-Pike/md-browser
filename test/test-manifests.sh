#!/bin/zsh
# Validates all plugin JSON files parse and carry required fields.
emulate -L zsh
set -e
root="${0:A:h}/.."
fail() { print -r -- "FAIL: $1"; exit 1; }

jq -e . "$root/.claude-plugin/plugin.json"      >/dev/null || fail "plugin.json invalid"
jq -e . "$root/.claude-plugin/marketplace.json" >/dev/null || fail "marketplace.json invalid"
jq -e . "$root/hooks/hooks.json"                >/dev/null || fail "hooks.json invalid"

[[ "$(jq -r '.name' "$root/.claude-plugin/plugin.json")" == "md-browser" ]] \
  || fail "plugin.json name must be md-browser"

matcher="$(jq -r '.hooks.PostToolUse[0].matcher' "$root/hooks/hooks.json")"
[[ "$matcher" == "Write|Edit|MultiEdit" ]] || fail "hooks matcher wrong: $matcher"

cmd="$(jq -r '.hooks.PostToolUse[0].hooks[0].command' "$root/hooks/hooks.json")"
[[ "$cmd" == '${CLAUDE_PLUGIN_ROOT}/bin/open-md.sh' ]] || fail "hook command wrong: $cmd"

print -r -- "PASS: manifests"
