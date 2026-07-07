---
description: Configure md-browser — pick your browser, Arc space, and which Markdown files auto-open.
---

You are running the guided setup for the **md-browser** plugin. Do all of the
following interactively, then write the config file. Never ask the user to edit
files by hand.

## 1. Detect installed browsers

Run this and note which are installed:

```bash
for entry in "Arc:company.thebrowser.Browser" \
             "Google Chrome:com.google.Chrome" \
             "Microsoft Edge:com.microsoft.edgemac" \
             "Brave Browser:com.brave.Browser"; do
  name="${entry%%:*}"; bid="${entry##*:}"
  if mdfind "kMDItemCFBundleIdentifier == '$bid'" 2>/dev/null | grep -q .; then
    echo "INSTALLED: $name"
  fi
done
```

## 2. Ask which browser to use

Use the AskUserQuestion tool. Offer ONLY the browsers reported INSTALLED above.
Store the chosen AppleScript app name exactly: `Arc`, `Google Chrome`,
`Microsoft Edge`, or `Brave Browser`.

## 3. If (and only if) the user chose Arc, ask for a Space

Launch Arc if needed, then list Space names:

```bash
osascript -e 'tell application "Arc" to return title of spaces of front window'
```

Use AskUserQuestion to present each Space name plus a "No specific space
(use the front window)" option. If they pick that, leave `space` unset.

## 4. Ask which Markdown files should auto-open (scope)

Use AskUserQuestion with these options:

- **All Markdown files** — omit `scope`.
- **Only specs & plans (recommended)** — `scope` = `["**/superpowers/**/*.md", "**/*-design.md", "**/*-plan.md"]`.
- **A specific folder** — ask for an absolute folder path `DIR`; `scope` = `["DIR/**/*.md"]`.
- **Custom** — ask for one or more glob patterns; use them as `scope`.

## 5. Write the config

Build the JSON with jq (omit absent keys) and write it to
`${CLAUDE_PLUGIN_DATA}/config.json`. Example for Arc + a space + presets:

```bash
mkdir -p "${CLAUDE_PLUGIN_DATA}"
jq -n \
  --arg browser "Arc" \
  --arg space "FS-Workbench" \
  --argjson scope '["**/superpowers/**/*.md","**/*-design.md","**/*-plan.md"]' \
  '{browser:$browser} + (if $space=="" then {} else {space:$space} end) + {scope:$scope}' \
  > "${CLAUDE_PLUGIN_DATA}/config.json"
cat "${CLAUDE_PLUGIN_DATA}/config.json"
```

Adjust the jq invocation to omit `space` and/or `scope` per the user's answers.

## 6. Confirm and offer a test

Show the written config. Offer to verify by writing a scratch file and
confirming it opens:

```bash
print '# md-browser test' > /tmp/mdb-setup-test.md
echo '{"tool_input":{"file_path":"/tmp/mdb-setup-test.md"}}' | \
  "${CLAUDE_PLUGIN_ROOT}/bin/open-md.sh"
```

If the scope excludes `/tmp/...`, tell the user the test file is out of scope
(so nothing opening is correct) and instead test with an in-scope path.
