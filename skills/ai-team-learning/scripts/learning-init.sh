#!/bin/bash
# Initialize the learning system for a project

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEARNING_DIR="$PROJECT_DIR/.claude/learnings"

echo "Initializing learning system in: $PROJECT_DIR"

# Create directory structure
mkdir -p "$LEARNING_DIR/sessions/archive"
mkdir -p "$LEARNING_DIR/agents"

# Initialize patterns file if not exists
if [ ! -f "$LEARNING_DIR/patterns.yaml" ]; then
    cat > "$LEARNING_DIR/patterns.yaml" << 'EOF'
# Effective patterns learned from past tasks
# Format:
#   - id: unique_identifier
#     description: What the pattern is
#     example: Example of applying the pattern
#     confidence: 0.0-1.0
#     reinforced: number of times confirmed
#     last_used: date

patterns: []
EOF
    echo "Created: patterns.yaml"
fi

# Initialize errors file if not exists
if [ ! -f "$LEARNING_DIR/errors.yaml" ]; then
    cat > "$LEARNING_DIR/errors.yaml" << 'EOF'
# Error patterns to avoid
# Format:
#   - id: unique_identifier
#     description: What the error is
#     prevention: How to prevent it
#     severity: low|medium|high
#     occurrences: count
#     last_seen: date

errors: []
EOF
    echo "Created: errors.yaml"
fi

# Initialize agent-specific learnings
for agent in gemini opencode; do
    if [ ! -f "$LEARNING_DIR/agents/$agent.yaml" ]; then
        cat > "$LEARNING_DIR/agents/$agent.yaml" << EOF
# Learnings specific to $agent
agent: $agent

effective_prompts: []
ineffective_prompts: []
common_issues: []
EOF
        echo "Created: agents/$agent.yaml"
    fi
done

echo ""
echo "Learning system initialized!"
echo "Directory: $LEARNING_DIR"
echo ""
echo "To start a new session, run:"
echo "  ./scripts/learning-session.sh start 'Task description'"
