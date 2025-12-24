#!/bin/bash
# Manage learning sessions

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEARNING_DIR="$PROJECT_DIR/.claude/learnings"
SESSIONS_DIR="$LEARNING_DIR/sessions"
CURRENT_SESSION="$SESSIONS_DIR/current.yaml"

usage() {
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  start <task>      Start a new learning session"
    echo "  log <stage> <insight> [confidence]  Log a learning"
    echo "  iteration <number>  Start a new iteration"
    echo "  complete          Complete and archive the session"
    echo "  status            Show current session status"
    echo "  recall [pattern]  Recall relevant learnings"
    exit 1
}

start_session() {
    local task="$1"
    if [ -z "$task" ]; then
        echo "Error: Task description required"
        exit 1
    fi

    local session_id=$(date +%Y%m%d-%H%M%S)

    # Archive existing session if any
    if [ -f "$CURRENT_SESSION" ]; then
        mv "$CURRENT_SESSION" "$SESSIONS_DIR/archive/${session_id}-incomplete.yaml"
        echo "Archived incomplete previous session"
    fi

    cat > "$CURRENT_SESSION" << EOF
session:
  id: "$session_id"
  started: "$(date -Iseconds)"
  task: "$task"
  status: in_progress

iterations: []

learnings: []

metrics:
  gemini_calls: 0
  opencode_calls: 0
  total_iterations: 0
EOF

    echo "Started new session: $session_id"
    echo "Task: $task"
    echo ""
    echo "Log learnings with: $0 log <stage> '<insight>' [confidence]"
}

log_learning() {
    local stage="$1"
    local insight="$2"
    local confidence="${3:-0.7}"

    if [ -z "$stage" ] || [ -z "$insight" ]; then
        echo "Error: Stage and insight required"
        echo "Usage: $0 log <stage> '<insight>' [confidence]"
        echo "Stages: plan, build, verify, qa, fix"
        exit 1
    fi

    if [ ! -f "$CURRENT_SESSION" ]; then
        echo "Error: No active session. Start one with: $0 start '<task>'"
        exit 1
    fi

    # Append learning to session file
    cat >> "$CURRENT_SESSION" << EOF

  - timestamp: "$(date -Iseconds)"
    stage: "$stage"
    insight: "$insight"
    confidence: $confidence
EOF

    echo "Logged learning:"
    echo "  Stage: $stage"
    echo "  Insight: $insight"
    echo "  Confidence: $confidence"
}

start_iteration() {
    local iteration_num="$1"
    if [ -z "$iteration_num" ]; then
        echo "Error: Iteration number required"
        exit 1
    fi

    if [ ! -f "$CURRENT_SESSION" ]; then
        echo "Error: No active session"
        exit 1
    fi

    cat >> "$CURRENT_SESSION" << EOF

  - iteration: $iteration_num
    started: "$(date -Iseconds)"
    what_worked: []
    what_failed: []
    adjustments: []
EOF

    # Update metrics
    sed -i "s/total_iterations: [0-9]*/total_iterations: $iteration_num/" "$CURRENT_SESSION"

    echo "Started iteration $iteration_num"
}

complete_session() {
    if [ ! -f "$CURRENT_SESSION" ]; then
        echo "Error: No active session to complete"
        exit 1
    fi

    local session_id=$(grep "id:" "$CURRENT_SESSION" | head -1 | sed 's/.*id: "\([^"]*\)".*/\1/')
    local task=$(grep "task:" "$CURRENT_SESSION" | head -1 | sed 's/.*task: "\([^"]*\)".*/\1/')

    # Update status
    sed -i 's/status: in_progress/status: completed/' "$CURRENT_SESSION"

    # Add completion timestamp
    cat >> "$CURRENT_SESSION" << EOF

retrospective:
  completed: "$(date -Iseconds)"
  outcome: "success"
  notes: "Add retrospective notes here"
EOF

    # Archive the session
    mv "$CURRENT_SESSION" "$SESSIONS_DIR/archive/${session_id}.yaml"

    echo "Session completed and archived: $session_id"
    echo "Task: $task"
    echo ""
    echo "Review retrospective: $SESSIONS_DIR/archive/${session_id}.yaml"
}

show_status() {
    if [ ! -f "$CURRENT_SESSION" ]; then
        echo "No active session"
        echo ""
        echo "Recent sessions:"
        ls -lt "$SESSIONS_DIR/archive/" 2>/dev/null | head -5
        exit 0
    fi

    echo "=== Current Session ==="
    grep -E "^  (id|task|status|started):" "$CURRENT_SESSION" | head -4
    echo ""
    echo "Learnings captured: $(grep -c "insight:" "$CURRENT_SESSION" 2>/dev/null || echo 0)"
    echo "Iterations: $(grep "total_iterations:" "$CURRENT_SESSION" | sed 's/.*: //')"
}

recall_learnings() {
    local pattern="$1"

    echo "=== Relevant Learnings ==="
    echo ""

    if [ -n "$pattern" ]; then
        echo "Searching for: $pattern"
        echo ""
        grep -r -l "$pattern" "$LEARNING_DIR"/*.yaml 2>/dev/null
        echo ""
        grep -r -A2 -B2 "$pattern" "$LEARNING_DIR"/*.yaml 2>/dev/null
    else
        echo "--- Patterns ---"
        cat "$LEARNING_DIR/patterns.yaml" 2>/dev/null | head -20

        echo ""
        echo "--- Errors to Avoid ---"
        cat "$LEARNING_DIR/errors.yaml" 2>/dev/null | head -20
    fi
}

# Main command router
case "$1" in
    start)
        start_session "$2"
        ;;
    log)
        log_learning "$2" "$3" "$4"
        ;;
    iteration)
        start_iteration "$2"
        ;;
    complete)
        complete_session
        ;;
    status)
        show_status
        ;;
    recall)
        recall_learnings "$2"
        ;;
    *)
        usage
        ;;
esac
