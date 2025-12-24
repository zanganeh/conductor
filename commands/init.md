---
description: Initialize Conductor - creates config file and directory structure
allowed-tools:
  - Bash
  - Read
  - Write
---

# Conductor Initialization

Initialize Conductor for this project.

## What This Does

1. Creates `.claude/ai-team-config.yaml` with model configuration
2. Creates `.claude/learnings/` directory for the learning loop
3. Sets up logging directories

## Run Initialization

Detect the platform and run the appropriate init script:

**On Windows (PowerShell):**
```powershell
& "$env:CLAUDE_PLUGIN_ROOT\scripts\ai-team-init.ps1"
```

**On Linux/macOS (Bash):**
```bash
"$CLAUDE_PLUGIN_ROOT/scripts/ai-team-init.sh"
```

## After Initialization

1. Review and customize `.claude/ai-team-config.yaml`
2. Run `/conductor:check` to verify everything is ready
3. Start working with `/conductor:work <task>`

## Configuration Options

The config file allows you to customize:

- **Gemini model**: Which model Gemini uses for building
- **OpenCode model**: Which model OpenCode uses for QA
- **Playwright settings**: Browser, headless mode, viewport
- **Learning settings**: Enable/disable, confidence thresholds
- **Workflow settings**: Verification, test generation, retrospectives
