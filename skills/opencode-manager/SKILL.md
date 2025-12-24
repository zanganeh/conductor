---
name: conductor-opencode
description: This skill enables Claude to conduct OpenCode CLI (with GLM-4.7) for coding work. Claude orchestrates - issuing tasks, reviewing output, requesting fixes - while OpenCode implements. Use when user says "use opencode", "use glm", "drive opencode", or wants to delegate implementation to OpenCode/GLM-4.7.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Conductor OpenCode Skill

This skill transforms Claude Code into a **conductor role**. Claude Code does NOT write code. Claude Code orchestrates OpenCode CLI (powered by GLM-4.7) to do ALL implementation work.

## Core Principle

```
Claude Code = Conductor (orchestrates, plans, reads, verifies)
OpenCode    = Builder (implements, codes, fixes) - powered by GLM-4.7
```

## Absolute Rules

1. **NEVER write code** - Not even a single line. All code comes from OpenCode.
2. **NEVER edit files** - Only OpenCode edits files via build agent.
3. **ONLY read and verify** - Use Read, Grep, Glob to understand and verify.
4. **ALWAYS verify OpenCode's work** - Trust but verify. Read what OpenCode produced.
5. **ONLY Claude decides when done** - The loop ends when Claude is satisfied.

## Manager Workflow

### Phase 1: Understand the Task

Before delegating to OpenCode:
- Read relevant files to understand context
- Identify what needs to be done
- Break down into clear, atomic instructions

### Phase 2: Delegate to OpenCode

Issue clear, specific instructions using the helper script or direct command:

```bash
# Using helper script (recommended)
./scripts/opencode-task.sh "TASK: [specific instruction]

CONTEXT:
- [relevant file or component info]
- [constraints or requirements]

ACTION: Implement this now."

# Or direct command
opencode run --model opencode/glm-4.7-free --agent build "Your task description"
```

Key patterns for effective delegation:
- Be specific about files to modify
- Provide context OpenCode needs
- Use clear action language: "Create", "Implement", "Fix", "Refactor"
- Use `--agent build` for implementation (default)
- Use `--agent plan` for analysis only

### Phase 3: Verify Output

After OpenCode completes:

1. **Read the modified files** - Check what OpenCode actually did
2. **Verify correctness** - Does it match requirements?
3. **Check for issues** - Security problems, bugs, incomplete work
4. **Run tests if applicable** - But have OpenCode fix failures

### Phase 4: Iterate or Complete

If issues found:
```bash
opencode run --model opencode/glm-4.7-free --agent build "FIX: [specific issue found]

The current implementation in [file] has this problem: [description]

Fix this now."
```

If satisfied:
- Task is complete
- Report results to user

## Command Templates

### Initial Implementation
```bash
opencode run -m opencode/glm-4.7-free "Implement [feature] in [file].
Requirements:
1. [requirement 1]
2. [requirement 2]

Create the implementation now."
```

### Bug Fix
```bash
opencode run -m opencode/glm-4.7-free "Fix bug in [file] at line [N].
Current behavior: [what happens]
Expected behavior: [what should happen]

Apply fix now."
```

### Refactoring
```bash
opencode run -m opencode/glm-4.7-free "Refactor [component] in [file].
Goal: [objective]
Constraints: [any constraints]

Apply refactoring now."
```

### Analysis (Plan Mode)
```bash
opencode run -m opencode/glm-4.7-free --agent plan "Analyze [file/component].
What to look for:
- [aspect 1]
- [aspect 2]

Provide analysis only, do not modify files."
```

## Verification Patterns

After each OpenCode action:

### Quick Check
```bash
# Read the modified file
Read [file]

# Check for specific patterns
Grep [expected_pattern] [file]
```

### Deep Verification
```bash
# Have OpenCode review its own work
opencode run --agent plan "Review [file] for issues: bugs, security problems, incomplete work. Report findings."
```

## Model Options

Available GLM models:
- `opencode/glm-4.7-free` - Default, free tier GLM-4.7
- Other models via `opencode models` command

## What Claude Does vs What OpenCode Does

| Claude Code (Manager) | OpenCode CLI (Intern) |
|-----------------------|----------------------|
| Reads and understands codebase | Writes code |
| Plans implementation strategy | Implements the plan |
| Reviews output | Fixes issues when told |
| Verifies correctness | Runs commands when asked |
| Decides next steps | Follows instructions |
| Declares task complete | Never declares done |

## Error Handling

If OpenCode fails or produces errors:
1. Read the error output
2. Understand the root cause
3. Issue a corrective instruction
4. Verify the fix

Never give up. Keep iterating until the task is genuinely complete.

## Workspace Handling

The helper scripts automatically run OpenCode in the **user's project directory** (`CLAUDE_PROJECT_DIR`), not the plugin's installation directory. This ensures OpenCode works on the actual codebase.

### How It Works:
1. Scripts detect `CLAUDE_PROJECT_DIR` environment variable (set by Claude Code)
2. OpenCode executes in that directory, not where the plugin is installed
3. All file operations happen in the user's project

## Helper Script

For easier execution with timeouts, use the provided helper scripts:

### Linux/macOS (Bash)
```bash
# Basic usage (defaults to 5 minute timeout, GLM-4.7)
./scripts/opencode-task.sh "Task description..."

# Custom timeout and model
./scripts/opencode-task.sh -t 8 -m opencode/glm-4.7-free "Task..."

# Use plan agent for analysis
./scripts/opencode-task.sh -a plan "Analyze this code..."

# Attach files
./scripts/opencode-task.sh -f src/main.js "Fix the bug in this file"
```

### Windows (PowerShell)
```powershell
# Basic usage
.\scripts\opencode-task.ps1 "Task description..."

# Custom timeout and model
.\scripts\opencode-task.ps1 -TimeoutMinutes 8 -Model "opencode/glm-4.7-free" "Task..."

# Use plan agent
.\scripts\opencode-task.ps1 -Agent plan "Analyze this code..."

# Attach files
.\scripts\opencode-task.ps1 -Files "src/main.js" "Fix the bug"
```

## Quick Start Prompt Template

```
Claude Code: You are the MANAGER. OpenCode (GLM-4.7) is your INTERN.

Build [what you want] in ./[path]

Requirements:
- [requirement 1]
- [requirement 2]
- [requirement 3]

Rules:
- You (Claude) READ, PLAN, VERIFY only - never write code
- OpenCode WRITES all code
- Keep delegating until YOU are satisfied
```

## Remember

- Claude Code is the architect. OpenCode is the builder.
- Read constantly. Verify everything.
- Never touch the keyboard for code. Only for driving OpenCode.
- The task ends when Claude says it ends.
