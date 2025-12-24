#!/bin/bash
# Promote a learning from session to persistent storage

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEARNING_DIR="$PROJECT_DIR/.claude/learnings"

usage() {
    echo "Usage: $0 <type> <id> <description> [confidence]"
    echo ""
    echo "Types:"
    echo "  pattern   A code/prompt pattern that works well"
    echo "  error     An error pattern to avoid"
    echo "  gemini    A Gemini-specific learning"
    echo "  opencode  An OpenCode-specific learning"
    echo ""
    echo "Example:"
    echo "  $0 pattern explicit_colors 'Use hex codes instead of color names' 0.9"
    echo "  $0 error workspace_rewrite 'Gemini rewrites paths outside workspace' 0.95"
    exit 1
}

promote_pattern() {
    local id="$1"
    local description="$2"
    local confidence="${3:-0.8}"

    cat >> "$LEARNING_DIR/patterns.yaml" << EOF

  - id: "$id"
    description: "$description"
    confidence: $confidence
    reinforced: 1
    learned_from: "$(date +%Y-%m-%d)"
    last_used: "$(date +%Y-%m-%d)"
EOF

    echo "Promoted pattern: $id"
    echo "  Description: $description"
    echo "  Confidence: $confidence"
}

promote_error() {
    local id="$1"
    local description="$2"
    local prevention="$3"
    local severity="${4:-medium}"

    cat >> "$LEARNING_DIR/errors.yaml" << EOF

  - id: "$id"
    description: "$description"
    prevention: "$prevention"
    severity: "$severity"
    occurrences: 1
    last_seen: "$(date +%Y-%m-%d)"
EOF

    echo "Promoted error pattern: $id"
    echo "  Description: $description"
    echo "  Severity: $severity"
}

promote_agent() {
    local agent="$1"
    local type="$2"
    local pattern="$3"
    local rate="${4:-0.8}"

    local agent_file="$LEARNING_DIR/agents/$agent.yaml"

    if [ "$type" = "effective" ]; then
        cat >> "$agent_file" << EOF

  - pattern: "$pattern"
    success_rate: $rate
    learned: "$(date +%Y-%m-%d)"
EOF
        echo "Promoted effective prompt pattern for $agent"
    else
        cat >> "$agent_file" << EOF

  - pattern: "$pattern"
    failure_rate: $rate
    learned: "$(date +%Y-%m-%d)"
EOF
        echo "Promoted ineffective prompt pattern for $agent"
    fi
}

reinforce_pattern() {
    local id="$1"
    local file="$LEARNING_DIR/patterns.yaml"

    if grep -q "id: \"$id\"" "$file"; then
        # Increment reinforced count (simplified - in production use proper YAML parser)
        echo "Reinforced pattern: $id"
        echo "(Note: Manual update of reinforced count needed in patterns.yaml)"
    else
        echo "Pattern not found: $id"
    fi
}

# Main
case "$1" in
    pattern)
        promote_pattern "$2" "$3" "$4"
        ;;
    error)
        promote_error "$2" "$3" "$4" "$5"
        ;;
    gemini)
        promote_agent "gemini" "$2" "$3" "$4"
        ;;
    opencode)
        promote_agent "opencode" "$2" "$3" "$4"
        ;;
    reinforce)
        reinforce_pattern "$2"
        ;;
    *)
        usage
        ;;
esac
