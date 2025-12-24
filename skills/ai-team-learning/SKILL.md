---
name: conductor-learning
description: Self-improving AI team workflow with reinforcement learning. Claude orchestrates, Gemini builds, OpenCode tests - and the system LEARNS from every iteration. Use for tasks where you want the AI team to get better over time, track patterns, and build institutional knowledge.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
---

# Conductor Learning Skill

A **self-improving AI orchestra** that learns from every interaction, building knowledge that makes future tasks faster and more accurate.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    LEARNING-ENHANCED WORKFLOW                   │
│                                                                 │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    │
│   │  PLAN   │───▶│  BUILD  │───▶│   QA    │───▶│  LEARN  │    │
│   │ +recall │    │ Gemini  │    │OpenCode │    │ +store  │    │
│   └─────────┘    └─────────┘    └─────────┘    └────┬────┘    │
│        ▲                                            │          │
│        │              ┌──────────────┐              │          │
│        └──────────────│   MEMORY     │◀─────────────┘          │
│                       │   .claude/   │                         │
│                       │  learnings/  │                         │
│                       └──────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

## Team Roles

| Role | AI | Responsibility |
|------|-----|----------------|
| **Conductor** | Claude Code | Orchestrates, delegates, reviews, **learns**, decides |
| **Builder** | Gemini CLI | Writes all code |
| **QA Tester** | OpenCode (GLM-4.7) | Tests in browser |
| **Memory** | File System | Stores learnings for future sessions |

## Learning Categories

### 1. Prompt Patterns
What instructions produce the best results?

### 2. Code Patterns
What structures/patterns produce quality results?

### 3. Error Patterns
What errors occur frequently and how to prevent them?

### 4. Project Patterns
What works for THIS specific codebase?

## Workflow with Learning

### Phase 0: Initialize Learning Session

At the START of every task:

```bash
# Create session log
mkdir -p .claude/learnings/sessions

# Start session file
cat > .claude/learnings/sessions/$(date +%Y%m%d-%H%M%S).yaml << 'EOF'
session:
  started: $(date -Iseconds)
  task: "[TASK DESCRIPTION]"
  status: in_progress

learnings: []
iterations: []
EOF
```

### Phase 1: Recall Relevant Learnings

Before planning, load past learnings:

```bash
# Check for existing learnings
cat .claude/learnings/patterns.yaml 2>/dev/null || echo "No prior learnings found"
cat .claude/learnings/errors.yaml 2>/dev/null || echo "No error patterns found"
```

Apply learnings to current plan:
- What worked before for similar tasks?
- What errors should we prevent?
- What patterns are effective?

### Phase 2: Plan (with learnings applied)

Create plan that incorporates past learnings:

```yaml
# Document planning decisions
plan:
  task: "Build portfolio website"

  applied_learnings:
    - "Use explicit hex colors (learned: 2024-12-23)"
    - "Break gallery into separate task (learned: 2024-12-20)"
    - "Always verify paths after build (learned: 2024-12-24)"

  steps:
    1. Create HTML structure
    2. Add hero section with dark gradient
    3. Build gallery grid
    4. Create contact form with validation
    5. Add responsive styles
```

### Phase 3: Build (Gemini) + Capture

Delegate to Gemini AND capture the interaction:

```bash
# Execute and capture
GEMINI_OUTPUT=$(cd $PROJECT_DIR && gemini "..." --yolo -o text 2>&1)

# Log the interaction
echo "
- timestamp: $(date -Iseconds)
  stage: build
  agent: gemini
  prompt_summary: '[what you asked]'
  outcome: '[success/failure]'
  observation: '[what happened]'
" >> .claude/learnings/sessions/current.yaml
```

### Phase 4: Verify + Capture Observations

Claude reviews the build:

```yaml
# Log verification findings
verification:
  files_created: [list]
  issues_found:
    - issue: "Missing mobile styles"
      severity: medium
      pattern_type: "common_omission"
  quality_score: 0.7
```

### Phase 5: QA (OpenCode) + Capture

Run QA and capture results:

```bash
# Execute QA
QA_OUTPUT=$(opencode run -m opencode/glm-4.7-free "QA TEST: ...")

# Log QA results
echo "
- timestamp: $(date -Iseconds)
  stage: qa
  agent: opencode
  tests_run: [list]
  passed: [count]
  failed: [count]
  issues:
    - description: '[issue]'
      root_cause: '[cause]'
      fix_needed: '[fix]'
" >> .claude/learnings/sessions/current.yaml
```

### Phase 6: Learn from Iteration

After each build→QA cycle, analyze and extract learnings:

```yaml
# Iteration analysis
iteration_learning:
  iteration: 1

  what_worked:
    - observation: "Grid layout instruction was clear"
      pattern: "Explicit CSS layout instructions work"
      confidence: 0.8

  what_failed:
    - observation: "Form validation incomplete"
      root_cause: "Didn't specify validation rules"
      fix: "Always list validation rules explicitly"
      pattern: "error_prevention"
      confidence: 0.9

  adjustments:
    - "Next iteration: include responsive breakpoints in prompt"
```

### Phase 7: Fix + Re-QA (Loop)

If issues found:
1. Extract learning from failure
2. Apply learning to fix instruction
3. Delegate fix to Gemini
4. Re-run QA
5. Capture new learnings

### Phase 8: Complete + Retrospective

When task is done, run retrospective:

```yaml
# Final retrospective
retrospective:
  task: "Build portfolio website"
  outcome: success

  metrics:
    iterations: 3
    gemini_calls: 5
    opencode_calls: 3
    time_elapsed: 45min

  key_learnings:
    - insight: "Breaking into atomic tasks reduces iterations"
      confidence: 0.9
      promote_to: project

    - insight: "OpenCode catches styling issues humans miss"
      confidence: 0.95
      promote_to: global

  patterns_reinforced:
    - "explicit_colors"
    - "mobile_first"

  new_patterns:
    - name: "gallery_grid"
      description: "Use CSS grid with auto-fit for galleries"
      confidence: 0.85
```

### Phase 9: Store Learnings

Promote valuable learnings to persistent storage:

```bash
# Update patterns file
cat >> .claude/learnings/patterns.yaml << 'EOF'
- pattern: gallery_grid
  description: "Use CSS grid with auto-fit for galleries"
  learned_from: portfolio_task_2024-12-24
  confidence: 0.85
  reinforced_count: 1
EOF
```

## Learning Storage Structure

```
.claude/
└── learnings/
    ├── patterns.yaml       # Effective code/prompt patterns
    ├── errors.yaml         # Known error patterns to avoid
    ├── agents/
    │   ├── gemini.yaml     # Gemini-specific learnings
    │   └── opencode.yaml   # OpenCode-specific learnings
    └── sessions/
        ├── current.yaml    # Active session log
        └── archive/        # Completed session logs
```

## Learning Record Formats

### Pattern Record
```yaml
patterns:
  - id: explicit_colors
    description: "Use hex color codes instead of color names"
    example: "Use #1a1a2e instead of 'dark blue'"
    learned_from: session_2024-12-23
    confidence: 0.9
    reinforced: 5
    last_used: 2024-12-24
```

### Error Record
```yaml
errors:
  - id: workspace_path_rewrite
    description: "Gemini silently rewrites paths outside workspace"
    prevention: "Always cd to target directory before gemini command"
    severity: high
    occurrences: 3
    last_seen: 2024-12-24
```

### Agent Learning Record
```yaml
gemini:
  effective_prompts:
    - pattern: "Be specific about file paths"
      success_rate: 0.95
    - pattern: "Include 'Apply changes now' as trigger"
      success_rate: 0.9

  ineffective_prompts:
    - pattern: "Multiple unrelated tasks in one prompt"
      failure_rate: 0.7
```

## Prompt Template with Learning

```
Claude Code: You are the CONDUCTOR of a self-improving development team.

Your team:
- GEMINI CLI = Builder (writes all code)
- OPENCODE (GLM-4.7) = QA Tester (tests in browser)
- MEMORY = Learning storage (.claude/learnings/)

Build [what you want] in ./[path]

Requirements:
- [requirement 1]
- [requirement 2]

Learning-Enhanced Workflow:
1. RECALL: Load relevant learnings from .claude/learnings/
2. PLAN: Apply learnings to your plan
3. BUILD: Delegate to Gemini, capture interaction
4. VERIFY: Review build, capture observations
5. QA: Delegate to OpenCode, capture results
6. LEARN: Extract insights from this iteration
7. FIX: If issues, apply learning and loop to BUILD
8. COMPLETE: Run retrospective, store new learnings

Rules:
- You (Claude) PLAN, DELEGATE, VERIFY, LEARN - never write app code
- Gemini BUILDS all application code
- OpenCode TESTS all functionality
- ALWAYS capture learnings at every stage
- ALWAYS run retrospective at end
- Store valuable learnings for future sessions
```

## Learning Commands

### Initialize Learning System
```bash
mkdir -p .claude/learnings/{sessions,archive,agents}
touch .claude/learnings/{patterns,errors}.yaml
```

### Start New Session
```bash
SESSION_ID=$(date +%Y%m%d-%H%M%S)
echo "session:
  id: $SESSION_ID
  started: $(date -Iseconds)
  task: '[TASK]'
  status: in_progress
learnings: []
iterations: []" > .claude/learnings/sessions/current.yaml
```

### Log Learning
```bash
echo "- timestamp: $(date -Iseconds)
  stage: [plan|build|qa|fix]
  insight: '[INSIGHT]'
  confidence: [0.0-1.0]
  action: '[ACTION TAKEN]'" >> .claude/learnings/sessions/current.yaml
```

### Complete Session
```bash
# Archive session
mv .claude/learnings/sessions/current.yaml \
   .claude/learnings/sessions/archive/$(date +%Y%m%d-%H%M%S).yaml
```

### Query Learnings
```bash
# Find relevant patterns
grep -l "portfolio\|gallery\|form" .claude/learnings/*.yaml

# Check error patterns
cat .claude/learnings/errors.yaml | grep -A5 "high"
```

## Confidence Scoring

Learnings have confidence scores (0.0 - 1.0):

| Score | Meaning | Action |
|-------|---------|--------|
| 0.0-0.3 | Weak signal | Observe more |
| 0.4-0.6 | Emerging pattern | Test hypothesis |
| 0.7-0.8 | Strong pattern | Apply cautiously |
| 0.9-1.0 | Proven pattern | Apply confidently |

### Confidence Adjustments
- **Reinforced**: +0.1 each time pattern succeeds
- **Contradicted**: -0.3 each time pattern fails
- **Decay**: -0.05 per month if not used

## Metrics to Track

| Metric | Purpose |
|--------|---------|
| Iterations per task | Measure improvement over time |
| Time to completion | Efficiency tracking |
| First-pass success rate | Quality of planning |
| Common error types | Prevention opportunities |
| Agent effectiveness | Optimize delegation |

## Evolution Path

### Level 1: Manual Logging
- Claude manually logs learnings
- Retrospective at end of task

### Level 2: Structured Capture
- Templates for logging
- Automatic pattern detection suggestions

### Level 3: Auto-Apply
- Learnings auto-injected into prompts
- Confidence-based application

### Level 4: Cross-Project
- Learnings shared across projects
- Community patterns

## Remember

- **Every iteration is a learning opportunity**
- **Capture failures as eagerly as successes**
- **Learnings compound over time**
- **Low-confidence learnings need validation**
- **High-confidence learnings should be applied automatically**
- **The system gets smarter with every task**
