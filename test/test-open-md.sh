#!/bin/zsh
# Tests open-md.sh with a stubbed osascript. No browser required.
emulate -L zsh
setopt extendedglob
root="${0:A:h}/.."
hook="$root/bin/open-md.sh"

pass=0; fail=0
check() { # desc expected actual
  if [[ "$2" == "$3" ]]; then print -r -- "  ok: $1"; ((pass++))
  else print -r -- "  FAIL: $1 (want '$2' got '$3')"; ((fail++)); fi
}

# Sandbox: fake PLUGIN_DATA + PLUGIN_ROOT with a stub osascript on PATH.
work="$(mktemp -d)"
export CLAUDE_PLUGIN_DATA="$work/data"
export CLAUDE_PLUGIN_ROOT="$work/root"
mkdir -p "$CLAUDE_PLUGIN_DATA" "$CLAUDE_PLUGIN_ROOT/bin" "$work/stubbin"
# Stub osascript: record argv to a log instead of running AppleScript.
cat > "$work/stubbin/osascript" <<'EOF'
#!/bin/zsh
shift  # skip the applescript path; record only the arguments
print -r -- "$@" >> "$OSA_LOG"
EOF
chmod +x "$work/stubbin/osascript"
export PATH="$work/stubbin:$PATH"
# Dummy applescript file so the path exists.
: > "$CLAUDE_PLUGIN_ROOT/bin/open-in-browser.applescript"

run() { # json  -> sets $OSA_LOG fresh, returns log contents
  export OSA_LOG="$work/osa.log"; : > "$OSA_LOG"
  print -r -- "$1" | zsh "$hook"
  cat "$OSA_LOG"
}

writecfg() { print -r -- "$1" > "$CLAUDE_PLUGIN_DATA/config.json"; }

# 1) No config yet -> no osascript call.
rm -f "$CLAUDE_PLUGIN_DATA/config.json"
check "no config = no-op" "" "$(run '{"tool_input":{"file_path":"/tmp/a.md"}}')"

# 2) Config present, markdown, no scope -> calls osascript with file:// + browser + space.
writecfg '{"browser":"Arc","space":"FS-Workbench"}'
check "md opens" "file:///tmp/a.md Arc FS-Workbench" "$(run '{"tool_input":{"file_path":"/tmp/a.md"}}')"

# 3) Non-markdown -> no call.
check "txt ignored" "" "$(run '{"tool_input":{"file_path":"/tmp/a.txt"}}')"

# 4) Empty space passed through as empty arg.
writecfg '{"browser":"Google Chrome"}'
check "no space arg empty" "file:///tmp/a.md Google Chrome " "$(run '{"tool_input":{"file_path":"/tmp/a.md"}}')"

# 5) Scope match.
writecfg '{"browser":"Arc","scope":["**/specs/**/*.md"]}'
check "in-scope opens" "file:///Users/x/specs/y/a.md Arc " "$(run '{"tool_input":{"file_path":"/Users/x/specs/y/a.md"}}')"

# 6) Scope miss -> no call.
check "out-of-scope skipped" "" "$(run '{"tool_input":{"file_path":"/Users/x/other/a.md"}}')"

# 7) Missing file_path -> no call.
writecfg '{"browser":"Arc"}'
check "no path no-op" "" "$(run '{"tool_input":{}}')"

print -r -- "---"; print -r -- "pass=$pass fail=$fail"
[[ $fail -eq 0 ]]
