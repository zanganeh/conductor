#!/usr/bin/env bash
#
# OPENCODE QA DELEGATOR
# =====================
# Delegates QA/testing work from Claude (Conductor) to OpenCode (Tester).
#
# CRITICAL: This script is for DELEGATION only.
# If OpenCode is slow or unresponsive, DO NOT take over testing yourself.
# Wait longer, retry with simpler tasks, or ask the user for guidance.
#
# Usage:
#   ./opencode-task.sh [options] "test description"
#   echo "test task" | ./opencode-task.sh [options]
#
# Options:
#   -m MODEL      Model to use (default: opencode/glm-4.7-free)
#   -a AGENT      Agent mode: build or plan (default: build)
#   -t MINUTES    Timeout (default: 5, max: 10)
#   -f FILE       File to attach (repeatable)
#   -h            Show help
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEOUT=5
readonly MAX_TIMEOUT=10
readonly EXIT_TIMEOUT=124
readonly DEFAULT_MODEL="opencode/glm-4.7-free"
readonly DEFAULT_AGENT="build"

# ============================================================================
# STATE VARIABLES
# ============================================================================

timeout_minutes=$DEFAULT_TIMEOUT
model_name="$DEFAULT_MODEL"
agent_mode="$DEFAULT_AGENT"
task_prompt=""
declare -a attached_files=()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

show_help() {
    cat << 'HELP'

OPENCODE QA DELEGATOR
=====================
Delegates QA/testing work from Claude (Conductor) to OpenCode (Tester).

REMINDER: If OpenCode is slow, DO NOT take over testing yourself.
          Wait longer, retry, or ask the user for guidance.

Usage:
    ./opencode-task.sh [options] "test description"
    echo "test task" | ./opencode-task.sh [options]

Options:
    -m MODEL      Model to use (default: opencode/glm-4.7-free)
    -a AGENT      Agent mode: build or plan (default: build)
    -t MINUTES    Timeout in minutes (default: 5, max: 10)
    -f FILE       File to attach (can repeat)
    -h            Show this help

Examples:
    ./opencode-task.sh "Test login form validation"
    ./opencode-task.sh -t 8 "Full QA on checkout flow"
    ./opencode-task.sh -a plan "Analyze test coverage"

HELP
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warning() {
    echo "[WARN] $*" >&2
}

get_working_directory() {
    if [[ -n "${CLAUDE_PROJECT_DIR:-}" && -d "$CLAUDE_PROJECT_DIR" ]]; then
        echo "$CLAUDE_PROJECT_DIR"
    else
        log_warning "CLAUDE_PROJECT_DIR not set. Using current directory."
        pwd
    fi
}

validate_agent_mode() {
    local mode="$1"

    if [[ "$mode" != "build" && "$mode" != "plan" ]]; then
        log_error "Agent mode must be 'build' or 'plan'."
        exit 1
    fi
}

validate_timeout() {
    local value="$1"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "Timeout must be a positive integer."
        exit 1
    fi

    if (( value > MAX_TIMEOUT )); then
        log_warning "Timeout $value exceeds max ($MAX_TIMEOUT). Using maximum."
        echo "$MAX_TIMEOUT"
    else
        echo "$value"
    fi
}

build_opencode_command() {
    local -a cmd_args=("run" "--model" "$model_name" "--agent" "$agent_mode")

    for file in "${attached_files[@]}"; do
        cmd_args+=("--file" "$file")
    done

    cmd_args+=("$task_prompt")

    printf '%s\n' "${cmd_args[@]}"
}

check_output_for_issues() {
    local output="$1"

    if echo "$output" | grep -iq "error\|failed\|exception"; then
        log_warning "OpenCode reported potential issues. Review output carefully."
        log_warning "If tests failed, delegate fixes to Gemini - do NOT fix them yourself."
    fi
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

while getopts ":m:a:t:f:h" opt; do
    case $opt in
        m) model_name="$OPTARG" ;;
        a) agent_mode="$OPTARG" ;;
        t) timeout_minutes="$OPTARG" ;;
        f) attached_files+=("$OPTARG") ;;
        h) show_help; exit 0 ;;
        :) log_error "Option -$OPTARG requires an argument."; exit 1 ;;
        \?) log_error "Invalid option: -$OPTARG"; show_help; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# ============================================================================
# INPUT VALIDATION
# ============================================================================

validate_agent_mode "$agent_mode"

# Get task from arguments or stdin
if [[ $# -ge 1 ]]; then
    task_prompt="$*"
elif [[ ! -t 0 ]]; then
    task_prompt="$(cat)"
fi

if [[ -z "$task_prompt" ]]; then
    log_error "No test task provided. Cannot delegate to OpenCode without instructions."
    show_help
    exit 1
fi

timeout_minutes=$(validate_timeout "$timeout_minutes")
timeout_seconds=$((timeout_minutes * 60))

# ============================================================================
# EXECUTION
# ============================================================================

work_dir="$(get_working_directory)"
cd "$work_dir" || {
    log_error "Cannot change to directory: $work_dir"
    exit 1
}

# Build command arguments
mapfile -t cmd_args < <(build_opencode_command)

# Execute with timeout
output=$(timeout "$timeout_seconds" opencode "${cmd_args[@]}" 2>&1) || exit_code=$?
exit_code=${exit_code:-0}

# Handle timeout
if [[ $exit_code -eq 124 ]]; then
    log_error "TIMEOUT: OpenCode did not complete within $timeout_minutes minutes."
    log_error "Options: 1) Increase timeout  2) Simplify task  3) Ask user"
    log_error "DO NOT take over and run tests yourself!"
    exit $EXIT_TIMEOUT
fi

# Check for issues in output
check_output_for_issues "$output"

# Output result
echo "$output"
exit $exit_code
