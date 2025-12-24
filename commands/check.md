---
description: Pre-flight check - verify all required tools are installed
allowed-tools:
  - Bash
  - Read
---

# Conductor Pre-flight Check

Run this before using `/conductor:work` to ensure all required tools are installed and configured.

## Checks Performed

### Required Tools
- **Gemini CLI** - For building code
- **OpenCode CLI** - For QA testing with GLM-4.7
- **Node.js 18+** - For Playwright MCP
- **npx** - For running Playwright

### Optional Tools
- **Playwright MCP** - Will download on first use if not cached

### Configuration
- **Config file** - `.claude/ai-team-config.yaml`
- **Learnings directory** - `.claude/learnings/`

### Environment
- **CLAUDE_PROJECT_DIR** - Project directory

## Run Check

Detect the platform and run the appropriate preflight script:

**On Windows (PowerShell):**
```powershell
& "$env:CLAUDE_PLUGIN_ROOT\scripts\preflight.ps1"
```

**On Linux/macOS (Bash):**
```bash
"$CLAUDE_PLUGIN_ROOT/scripts/preflight.sh"
```

## Interpreting Results

- **✓ Green** - Check passed
- **⚠ Yellow** - Warning (plugin will work but feature may be limited)
- **✗ Red** - Error (must fix before using `/conductor:work`)

## Fixing Issues

### Gemini CLI not found
```bash
npm install -g @google/generative-ai-cli
```

### OpenCode CLI not found
```bash
npm install -g opencode-ai
```

### Node.js not found or too old
Download from https://nodejs.org/ (version 18+)

### Config not found
Run `/conductor:init` to create configuration

## Next Steps

Once all checks pass:
```
/conductor:work create portfolio website for Aria Zanganeh
```
