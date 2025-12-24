#!/bin/bash
# Initialize AI Team Plugin for a project

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CONFIG_DIR="$PROJECT_DIR/.claude"
CONFIG_FILE="$CONFIG_DIR/ai-team-config.yaml"
LEARNINGS_DIR="$CONFIG_DIR/learnings"

echo "============================================"
echo "  AI Team Plugin - Initialization"
echo "============================================"
echo ""
echo "Project directory: $PROJECT_DIR"
echo ""

# Create .claude directory
mkdir -p "$CONFIG_DIR"
echo "✓ Created: $CONFIG_DIR"

# Create config file if not exists
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# AI Team Plugin Configuration
# ============================
# Configure models and settings for each AI team member

# Model Configuration
models:
  # Manager (Claude) - controlled by Claude Code, not configurable here
  # manager: claude-sonnet-4  # This is set by Claude Code itself

  # Builder (Gemini CLI)
  gemini:
    model: "gemini-2.5-pro"           # Default model for building
    # Alternative models:
    # - gemini-2.5-flash              # Faster, cheaper
    # - gemini-2.5-pro                # More capable
    timeout_minutes: 5                 # Max time per task
    options:
      yolo: true                       # Auto-approve changes

  # QA Tester (OpenCode with GLM)
  opencode:
    model: "opencode/glm-4.7-free"    # Default model for QA
    # Alternative models:
    # - opencode/glm-4.7-free         # Free tier
    # - anthropic/claude-sonnet-4     # Use Claude for QA
    # - openai/gpt-4                  # Use GPT-4 for QA
    timeout_minutes: 5
    agent: "build"                     # build or plan

# UI/UX Designer Configuration (Optional)
ui_ux:
  enabled: true                        # Enable UI/UX review capability
  auto_review: true                    # Let manager decide when to run UI/UX review
  # Set auto_review: false to only run when explicitly requested

  review_criteria:
    visual_hierarchy: true             # Check heading sizes, prominence
    color_contrast: true               # Check accessibility and cohesion
    spacing_layout: true               # Check whitespace and alignment
    typography: true                   # Check font choices and readability
    user_experience: true              # Check navigation and flow
    responsive_design: true            # Check mobile compatibility
    modern_patterns: true              # Check for outdated design patterns

  screenshot:
    full_page: true                    # Capture full scrollable page
    viewport_only: false               # Or just visible viewport

# Playwright Configuration
playwright:
  browser: "chromium"                  # chromium, firefox, webkit, msedge
  headless: false                      # Show browser window
  viewport: "1280x720"                 # Browser viewport size
  timeout_seconds: 30                  # Page load timeout

# Learning Configuration
learning:
  enabled: true                        # Enable learning loop
  auto_capture: true                   # Auto-capture learnings
  confidence_threshold: 0.7            # Min confidence to apply learning
  max_iterations: 10                   # Max dev↔qa loops before asking user

# Workflow Configuration
workflow:
  verify_builds: true                  # Claude verifies after each build
  generate_test_cases: true            # Generate test cases before testing
  run_regression: true                 # Run regression tests after fixes
  create_retrospective: true           # Create retrospective on completion

# Output Configuration
output:
  verbose: false                       # Detailed logging
  save_logs: true                      # Save session logs
  log_dir: ".claude/logs"              # Log directory
EOF
    echo "✓ Created: $CONFIG_FILE"
else
    echo "⚠ Config already exists: $CONFIG_FILE"
fi

# Create learnings directory structure
mkdir -p "$LEARNINGS_DIR/sessions/archive"
mkdir -p "$LEARNINGS_DIR/agents"
echo "✓ Created: $LEARNINGS_DIR"

# Create patterns file
if [ ! -f "$LEARNINGS_DIR/patterns.yaml" ]; then
    cat > "$LEARNINGS_DIR/patterns.yaml" << 'EOF'
# Effective patterns learned from past tasks
patterns: []
EOF
    echo "✓ Created: patterns.yaml"
fi

# Create errors file
if [ ! -f "$LEARNINGS_DIR/errors.yaml" ]; then
    cat > "$LEARNINGS_DIR/errors.yaml" << 'EOF'
# Error patterns to avoid
errors: []
EOF
    echo "✓ Created: errors.yaml"
fi

# Create agent-specific files
for agent in gemini opencode; do
    if [ ! -f "$LEARNINGS_DIR/agents/$agent.yaml" ]; then
        cat > "$LEARNINGS_DIR/agents/$agent.yaml" << EOF
# Learnings specific to $agent
agent: $agent
effective_prompts: []
ineffective_prompts: []
EOF
        echo "✓ Created: agents/$agent.yaml"
    fi
done

# Create logs directory
mkdir -p "$CONFIG_DIR/logs"
echo "✓ Created: logs directory"

echo ""
echo "============================================"
echo "  Initialization Complete!"
echo "============================================"
echo ""
echo "Configuration file: $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "1. Edit $CONFIG_FILE to customize models"
echo "2. Run pre-flight check: ./scripts/preflight.sh"
echo "3. Start working: /ai:work <your task>"
echo ""
