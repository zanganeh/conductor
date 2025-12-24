# Conductor

> Orchestrate multi-AI development teams

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-3.0.0-blue)](https://github.com/alchemiststudiosDOTai/conductor/releases)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-purple)](https://claude.ai)

A Claude Code plugin that transforms Claude into a **conductor** orchestrating a team of specialized AI agents:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CONDUCTOR (Claude)                           │
│                              │                                      │
│     ┌────────────────────────┼────────────────────────┐            │
│     ▼                        ▼                        ▼            │
│ ┌──────────┐          ┌──────────┐             ┌──────────┐        │
│ │  UI/UX   │──specs──▶│   DEV    │──build────▶│    QA    │        │
│ │ Gemini   │          │ Gemini   │             │ OpenCode │        │
│ │ (design) │◄─validate│ (build)  │◄───fixes───│  (test)  │        │
│ └──────────┘          └──────────┘             └──────────┘        │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Agent Orchestration** - Claude conducts, specialized AIs perform
- **UI/UX Design Phase** - Design specs before development
- **UI/UX Validation** - Compare implementation against specs after QA
- **Learning Loop** - System improves from every iteration
- **Automated QA** - OpenCode + Playwright integration

## Team Structure

| Role | AI | Responsibility |
|------|-----|----------------|
| **Conductor** | Claude | Orchestrate, delegate, verify, learn, decide |
| **Builder** | Gemini CLI | Write all code (`--yolo` mode) |
| **UI/UX Designer** | Gemini CLI | Design specs (pre-dev) & validation (post-QA) |
| **QA Tester** | OpenCode (GLM-4.7) | Generate test cases, run Playwright tests |

## Workflow

```
Phase 0: Pre-flight     → Check tools & config
Phase 1: Plan           → Break down task
Phase 2: UI/UX Design   → Generate design specs
Phase 3: Build          → Dev implements using specs
Phase 4: QA             → Test functionality
Phase 5: Dev ↔ QA Loop  → Fix issues until tests pass
Phase 6: UI/UX Validate → Compare against original specs
Phase 7: Complete       → Store learnings, report done
```

## Installation

### Plugin Marketplace (Recommended)

```bash
# Add marketplace
/plugin marketplace add alchemiststudiosDOTai/conductor

# Install plugin
/plugin install conductor
```

### Manual Installation

```bash
# Clone
git clone https://github.com/alchemiststudiosDOTai/conductor.git

# Copy to personal skills (all projects)
cp -r conductor/skills/* ~/.claude/skills/
cp -r conductor/commands/* ~/.claude/commands/

# Or copy to project skills (this project only)
cp -r conductor/skills/* ./.claude/skills/
cp -r conductor/commands/* ./.claude/commands/
```

## Quick Start

```bash
# Initialize (creates config)
/conductor:init

# Check tools are ready
/conductor:check

# Start working
/conductor:work create portfolio website for Aria Zanganeh
```

## Commands

| Command | Description |
|---------|-------------|
| `/conductor:init` | Initialize config and directories |
| `/conductor:check` | Pre-flight check for required tools |
| `/conductor:work <task>` | Execute full workflow for task |

## Skills

| Skill | Description |
|-------|-------------|
| `conductor-orchestrator` | Full team orchestration |
| `conductor-learning` | Learning loop with memory |
| `conductor-gemini` | Gemini-only delegation |
| `conductor-opencode` | OpenCode-only delegation |

## Requirements

- **Gemini CLI** - `npm install -g @google/generative-ai-cli`
- **OpenCode CLI** - For QA testing with GLM-4.7
- **Node.js 18+** - For Playwright

## Configuration

After `/conductor:init`, customize `.claude/ai-team-config.yaml`:

```yaml
models:
  gemini:
    model: gemini-2.5-pro
  opencode:
    model: opencode/glm-4.7-free

workflow:
  ui_ux_design: true      # Enable design phase
  ui_ux_validation: true  # Enable validation phase
  learning_enabled: true  # Enable learning loop

playwright:
  browser: chromium
  headless: false
```

## Example

```
User: /conductor:work create portfolio website for Aria Zanganeh

Claude (Conductor):
1. Plan: Break down into sections
2. UI/UX Design: Get design specs (colors, typography, layout)
3. Build: Delegate to Gemini with specs
4. QA: OpenCode generates tests, runs Playwright
5. Fix Loop: Iterate until tests pass
6. UI/UX Validate: Compare against original specs
7. Learn: Store insights for future tasks
8. Complete: Report done
```

## License

MIT © alchemiststudiosDOTai

---

**Conductor** - *Claude conducts, specialized AIs perform.*
