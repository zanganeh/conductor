# Learning Loop Architecture Design

## Vision

Transform the AI team from a **static workflow** into a **self-improving system** that learns from every interaction, building institutional knowledge that makes future tasks faster and more accurate.

```
┌─────────────────────────────────────────────────────────────────┐
│                    REINFORCEMENT LEARNING LOOP                  │
│                                                                 │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    │
│   │  PLAN   │───▶│ EXECUTE │───▶│   QA    │───▶│  LEARN  │    │
│   └─────────┘    └─────────┘    └─────────┘    └────┬────┘    │
│        ▲                                            │          │
│        │              ┌──────────────┐              │          │
│        └──────────────│   MEMORY     │◀─────────────┘          │
│                       │   STORE      │                         │
│                       └──────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

## Core Concept: Learning at Every Stage

### What Can Be Learned?

| Stage | Learnable Insights | Example |
|-------|-------------------|---------|
| **Planning** | Task decomposition patterns | "Forms need validation + styling + submission handler" |
| **Building** | Code patterns that work | "Gemini produces better CSS with specific color values" |
| **QA** | Common failure patterns | "Contact forms often fail email validation" |
| **Fixing** | Effective fix strategies | "Styling issues need full CSS context, not just the broken part" |
| **Completion** | Success patterns | "Portfolio sites work best with grid layouts" |

## Learning Categories

### 1. **Prompt Engineering Learnings**
What instructions produce the best results from each AI?

```yaml
gemini:
  effective_patterns:
    - "Be specific about file paths"
    - "Include surrounding code context for edits"
    - "Use 'Apply changes now' as action trigger"
  ineffective_patterns:
    - "Vague instructions like 'make it better'"
    - "Multiple unrelated tasks in one prompt"

opencode:
  effective_patterns:
    - "List specific test cases with expected outcomes"
    - "Provide URL/path to test target"
  ineffective_patterns:
    - "Open-ended 'test everything' requests"
```

### 2. **Code Pattern Learnings**
What code structures/patterns produce quality results?

```yaml
patterns:
  contact_forms:
    required_elements:
      - client_side_validation
      - error_message_display
      - submit_handler
      - loading_state
    common_issues:
      - missing_email_regex
      - no_error_styling

  portfolios:
    effective_structure:
      - hero_with_gradient_overlay
      - grid_gallery_with_lightbox
      - responsive_breakpoints
```

### 3. **Error Pattern Learnings**
What errors occur frequently and how to prevent them?

```yaml
errors:
  gemini:
    - pattern: "creates file in wrong location"
      cause: "workspace restriction"
      prevention: "always cd to target directory first"

    - pattern: "incomplete implementation"
      cause: "task too large"
      prevention: "break into smaller atomic tasks"

  opencode:
    - pattern: "cannot access localhost"
      cause: "server not running"
      prevention: "verify server is running before QA"
```

### 4. **Project-Specific Learnings**
What works for THIS specific codebase?

```yaml
project_learnings:
  tech_stack: "vanilla HTML/CSS/JS"
  conventions:
    - "use kebab-case for CSS classes"
    - "inline styles for simple components"
  known_issues:
    - "forms need explicit width on mobile"
```

## Memory Store Design

### Structure

```
.claude/
└── learnings/
    ├── global/                    # Cross-project learnings
    │   ├── gemini-patterns.yaml   # What works with Gemini
    │   ├── opencode-patterns.yaml # What works with OpenCode
    │   └── error-catalog.yaml     # Known error patterns
    │
    └── project/                   # Project-specific learnings
        ├── patterns.yaml          # Code patterns for this project
        ├── session-log.yaml       # Current session learnings
        └── retrospectives/        # Post-task analysis
            └── 2024-12-24-portfolio.yaml
```

### Learning Record Format

```yaml
# Example: session-log.yaml
session:
  id: "2024-12-24-001"
  task: "Build portfolio website"

learnings:
  - timestamp: "2024-12-24T10:30:00"
    stage: "build"
    agent: "gemini"
    observation: "First attempt created files in plugin directory"
    insight: "Must cd to project directory before delegating"
    action: "Added workspace check to workflow"
    confidence: 0.9

  - timestamp: "2024-12-24T10:45:00"
    stage: "qa"
    agent: "opencode"
    observation: "Gallery images not loading"
    root_cause: "Used relative paths without base"
    fix_applied: "Changed to absolute paths"
    pattern_type: "error_prevention"
    confidence: 0.8

metrics:
  total_iterations: 3
  gemini_calls: 5
  opencode_calls: 2
  time_to_completion: "45min"
  quality_score: 0.85
```

## Learning Integration Points

### 1. Pre-Task Learning Injection

Before starting a task, Claude queries relevant learnings:

```
SYSTEM: Loading relevant learnings for task type "portfolio website"...

LEARNINGS APPLIED:
- Gemini works best with explicit color hex values (confidence: 0.9)
- Gallery sections need responsive grid with auto-fit (confidence: 0.85)
- Contact forms require both client and visual validation feedback (confidence: 0.95)
- Previous issue: images in wrong path - always verify paths after build (confidence: 0.9)
```

### 2. Real-Time Learning Capture

During execution, capture observations:

```python
def capture_learning(stage, agent, observation, outcome):
    learning = {
        "timestamp": now(),
        "stage": stage,
        "agent": agent,
        "observation": observation,
        "outcome": outcome,  # success/failure
        "context": get_current_context()
    }

    # Immediate pattern matching
    if matches_known_pattern(learning):
        reinforce_pattern(learning)
    else:
        store_new_observation(learning)
```

### 3. Post-Iteration Analysis

After each build→QA cycle:

```yaml
iteration_analysis:
  iteration: 2

  what_worked:
    - "Specific CSS grid instructions produced correct layout"
    - "Listing test cases helped OpenCode focus"

  what_failed:
    - "Form validation was incomplete"
    - "Missing mobile responsive styles"

  adjustments_for_next:
    - "Include 'mobile responsive' in every styling task"
    - "Always specify validation rules explicitly"
```

### 4. Post-Task Retrospective

After task completion:

```yaml
retrospective:
  task: "Build portfolio website"
  outcome: "success"

  key_learnings:
    - insight: "Breaking gallery into separate task improved quality"
      confidence: 0.9
      applicable_to: ["gallery", "image-heavy", "grid-layouts"]

    - insight: "OpenCode found 3 issues Gemini missed"
      confidence: 0.95
      applicable_to: ["all-tasks"]
      action: "Always run QA even if build looks correct"

  metrics_vs_baseline:
    iterations: 3 (baseline: 5, improvement: 40%)
    time: 45min (baseline: 60min, improvement: 25%)

  promoted_to_global: true
```

## Feedback Loop Implementation

### Confidence Scoring

```python
def calculate_confidence(learning):
    factors = {
        "repetition": count_similar_observations(learning),
        "recency": time_decay_factor(learning.timestamp),
        "outcome_consistency": measure_outcome_consistency(learning),
        "cross_project": appears_in_other_projects(learning)
    }

    return weighted_average(factors)
```

### Learning Promotion

```
Local (session) → Project → Global

Promotion criteria:
- Appears 3+ times with consistent outcomes
- Confidence > 0.8
- Applicable beyond single task type
```

### Learning Decay

```python
def apply_decay(learning):
    # Learnings lose confidence if:
    # - Not reinforced in 30 days
    # - Contradicted by new observations
    # - Technology/context changed

    if days_since_last_reinforcement > 30:
        learning.confidence *= 0.9

    if contradicted_recently:
        learning.confidence *= 0.5
```

## Workflow with Learning Loop

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  1. TASK RECEIVED                                                    │
│     │                                                                │
│     ▼                                                                │
│  2. LOAD RELEVANT LEARNINGS ◄─────────────────────────────┐         │
│     │                                                      │         │
│     ▼                                                      │         │
│  3. PLAN (with learnings applied)                          │         │
│     │                                                      │         │
│     ├──► CAPTURE: planning decisions                       │         │
│     │                                                      │         │
│     ▼                                                      │         │
│  4. BUILD (Gemini)                                         │         │
│     │                                                      │         │
│     ├──► CAPTURE: what worked, what failed                 │         │
│     │                                                      │         │
│     ▼                                                      │         │
│  5. VERIFY (Claude)                                        │         │
│     │                                                      │         │
│     ├──► CAPTURE: code quality observations                │         │
│     │                                                      │         │
│     ▼                                                      │         │
│  6. QA (OpenCode)                                          │         │
│     │                                                      │         │
│     ├──► CAPTURE: test results, failures, root causes      │         │
│     │                                                      │         │
│     ▼                                                      │         │
│  7. ISSUES FOUND?                                          │         │
│     │                                                      │         │
│     ├─YES─► 8. ANALYZE FAILURE ──► LEARN ──► goto 4        │         │
│     │                                                      │         │
│     └─NO──► 9. TASK COMPLETE                               │         │
│             │                                              │         │
│             ▼                                              │         │
│         10. RETROSPECTIVE ──► STORE LEARNINGS ─────────────┘         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Implementation Approach

### Phase 1: Session Logging (Simple)
- Log all interactions to session file
- Manual retrospective at end
- No automatic learning application

### Phase 2: Pattern Recognition (Intermediate)
- Automatically detect repeated patterns
- Suggest learnings to Claude during planning
- Track success/failure metrics

### Phase 3: Automatic Application (Advanced)
- Pre-inject relevant learnings into prompts
- Automatically adjust agent instructions based on past performance
- Self-improving prompt templates

### Phase 4: Cross-Project Intelligence (Future)
- Share learnings across projects
- Build global knowledge base
- Community-contributed patterns

## Questions to Resolve

1. **Storage**: File-based YAML vs SQLite vs external service?
2. **Privacy**: What learnings are safe to share globally?
3. **Conflicts**: How to handle contradictory learnings?
4. **Context**: How much context to store with each learning?
5. **Retrieval**: How to efficiently find relevant learnings for new tasks?

## Next Steps

1. Implement basic session logging
2. Create learning capture functions in skill
3. Build retrospective template
4. Test on real tasks and iterate
