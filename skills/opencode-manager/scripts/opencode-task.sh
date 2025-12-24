#!/bin/bash

# Default values
TIMEOUT_MIN=5
MODEL="opencode/glm-4.7-free"
AGENT="build"
TASK=""
FILES=()

# Function to display usage
usage() {
    echo "Usage: $0 [-m model] [-a agent] [-t timeout_minutes] [-f file] [task_description]"
    echo "  -m model    : Model in provider/model format (default: opencode/glm-4.7-free)"
    echo "  -a agent    : Agent to use: build or plan (default: build)"
    echo "  -t minutes  : Timeout in minutes (default: 5, max: 10)"
    echo "  -f file     : File to attach to message (can be repeated)"
    echo "  task_description : The task prompt (optional if provided via stdin)"
    exit 1
}

# Parse options
while getopts ":m:t:a:f:" opt; do
  case ${opt} in
    m)
      MODEL="${OPTARG}"
      ;;
    t)
      TIMEOUT_MIN="${OPTARG}"
      ;;
    a)
      AGENT="${OPTARG}"
      ;;
    f)
      FILES+=("${OPTARG}")
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      usage
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# Determine working directory: use CLAUDE_PROJECT_DIR if available
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    PROJECT_DIR="$CLAUDE_PROJECT_DIR"
else
    PROJECT_DIR=$(pwd)
    echo "Warning: CLAUDE_PROJECT_DIR not set. Using current directory: $PROJECT_DIR" >&2
fi

# Validate agent
if [ "$AGENT" != "build" ] && [ "$AGENT" != "plan" ]; then
    echo "Error: Agent must be 'build' or 'plan'." >&2
    exit 1
fi

# Validate and cap timeout
if ! [[ "$TIMEOUT_MIN" =~ ^[0-9]+$ ]]; then
    echo "Error: Timeout must be an integer (minutes)." >&2
    exit 1
fi

if [ "$TIMEOUT_MIN" -gt 10 ]; then
    echo "Warning: Timeout of $TIMEOUT_MIN minutes exceeds limit. Capping at 10 minutes." >&2
    TIMEOUT_MIN=10
fi

# Convert minutes to seconds for the timeout command
TIMEOUT_SEC=$((TIMEOUT_MIN * 60))

# Get task description from argument or stdin
if [ $# -ge 1 ]; then
    TASK="$*"
else
    # Check if stdin has data
    if [ ! -t 0 ]; then
        TASK=$(cat)
    fi
fi

if [ -z "$TASK" ]; then
    echo "Error: No task description provided." >&2
    usage
fi

# Build the opencode command arguments
CMD="opencode"
ARGS=("run" "--model" "$MODEL" "--agent" "$AGENT")

# Add files if specified
for file in "${FILES[@]}"; do
    ARGS+=("--file" "$file")
done

# Add the task as the last argument
ARGS+=("$TASK")

# Change to project directory before executing
cd "$PROJECT_DIR" || {
    echo "Error: Cannot change to project directory: $PROJECT_DIR" >&2
    exit 1
}

# Use project directory as workspace reference
WORKSPACE="$PROJECT_DIR"

# Execution with timeout
OUTPUT=$(timeout "$TIMEOUT_SEC" "$CMD" "${ARGS[@]}" 2>&1)
CMD_EXIT_CODE=$?

# Check for timeout (exit code 124 is standard for GNU timeout)
if [ $CMD_EXIT_CODE -eq 124 ]; then
    echo "Error: Operation timed out after ${TIMEOUT_MIN} minutes." >&2
    exit 124
fi

# Check for common errors
if echo "$OUTPUT" | grep -qi "error\|failed"; then
    echo "Warning: OpenCode reported potential issues. Review output carefully." >&2
fi

# Print the captured output
echo "$OUTPUT"

# Exit with the command's exit code
exit $CMD_EXIT_CODE
