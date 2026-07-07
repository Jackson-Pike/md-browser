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

# AppleScript must compile (terminology resolves). Requires Chrome installed
# for the `using terms from application "Google Chrome"` block.
if osacompile -o /dev/null "$root/bin/open-in-browser.applescript" 2>/tmp/osa-compile.err; then
  print -r -- "  ok: applescript compiles"
else
  print -r -- "  WARN: applescript did not compile (is Google Chrome installed?):"
  cat /tmp/osa-compile.err
fi

print -r -- "PASS: manifests"
