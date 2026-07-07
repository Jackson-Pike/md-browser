# md-browser

A Claude Code plugin (macOS) that opens each Markdown file you edit in your
chosen Chromium browser — Arc, Chrome, Edge, or Brave — reloading the existing
tab instead of opening duplicates. Arc users can route previews to a specific
Space.

## Install

```
/plugin marketplace add Jackson-Pike/md-browser
/plugin install md-browser@md-browser
```

## Set up (required — one time)

```
/md-browser:setup
```

Pick your browser, an Arc Space (if using Arc), and which Markdown files should
auto-open (all, specs & plans only, a specific folder, or custom globs). The
command writes your config; there is nothing to edit by hand.

## How it works

A PostToolUse hook fires when Claude writes/edits a `.md` file. If the path is in
scope, it opens/reloads it in your configured browser via AppleScript. Config
lives at `${CLAUDE_PLUGIN_DATA}/config.json` and survives plugin updates.

## Requirements

- macOS, `jq`, and one of: Arc, Google Chrome, Microsoft Edge, Brave.

## Reconfigure

Re-run `/md-browser:setup` at any time — it overwrites the config.
