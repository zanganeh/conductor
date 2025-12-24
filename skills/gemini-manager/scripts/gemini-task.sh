#!/usr/bin/env bash
#
# GEMINI TASK DELEGATOR
# =====================
# Delegates implementation work from Claude (Conductor) to Gemini (Builder).
#
# IMPORTANT: This script is for DELEGATION only.
# Claude should NEVER write code itself, even if Gemini is slow.
#
# Usage:
#   ./gemini-task.sh [options] "task description"
#   echo "task" | ./gemini-task.sh [options]
#
# Options:
#   -m MODEL      Gemini model to use
#   -t MINUTES    Timeout (default: 5, max: 10)
#   -q            Quiet mode (suppress stderr)
#   -i DIRECTORY  Extra workspace directory (repeatable)
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

# ============================================================================
# STATE VARIABLES
# ============================================================================

timeout_minutes=$DEFAULT_TIMEOUT
model_name=""
quiet_mode=false
task_prompt=""
declare -a extra_paths=()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

show_help() {
    cat << 'HELP'

GEMINI TASK DELEGATOR
=====================
Delegates implementation work from Claude (Conductor) to Gemini (Builder).

Usage:
    ./gemini-task.sh [options] "task description"
    echo "task" | ./gemini-task.sh [options]

Options:
    -m MODEL      Gemini model to use
    -t MINUTES    Timeout in minutes (default: 5, max: 10)
    -q            Quiet mode (suppress stderr)
    -i DIRECTORY  Additional workspace directory (can repeat)
    -h            Show this help

Examples:
    ./gemini-task.sh "Build a responsive navbar"
    ./gemini-task.sh -t 8 -m gemini-2.5-pro "Refactor auth module"
    ./gemini-task.sh -i /shared/lib "Use shared utilities"

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

build_gemini_command() {
    local -a cmd_args=("--yolo" "-o" "text")

    if [[ -n "$model_name" ]]; then
        cmd_args+=("--model" "$model_name")
    fi

    for dir in "${extra_paths[@]}"; do
        cmd_args+=("--include-directories" "$dir")
    done

    cmd_args+=("$task_prompt")

    printf '%s\n' "${cmd_args[@]}"
}

check_workspace_errors() {
    local output="$1"
    local workspace="$2"

    if echo "$output" | grep -q "must be within one of the workspace directories"; then
        log_error "WORKSPACE RESTRICTION: Gemini cannot write outside: $workspace"
        log_error "Use -i flag to include additional directories."
        return 1
    fi

    if echo "$output" | grep -q "File path must be within"; then
        log_warning "PATH REWRITE DETECTED: Gemini may have changed target location."
        log_warning "Verify files are in expected location: $workspace"
    fi

    return 0
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

while getopts ":m:t:qi:h" opt; do
    case $opt in
        m) model_name="$OPTARG" ;;
        t) timeout_minutes="$OPTARG" ;;
        q) quiet_mode=true ;;
        i) extra_paths+=("$OPTARG") ;;
        h) show_help; exit 0 ;;
        :) log_error "Option -$OPTARG requires an argument."; exit 1 ;;
        \?) log_error "Invalid option: -$OPTARG"; show_help; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# ============================================================================
# INPUT VALIDATION
# ============================================================================

# Get task from arguments or stdin
if [[ $# -ge 1 ]]; then
    task_prompt="$*"
elif [[ ! -t 0 ]]; then
    task_prompt="$(cat)"
fi

if [[ -z "$task_prompt" ]]; then
    log_error "No task provided. Cannot delegate to Gemini without instructions."
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
mapfile -t cmd_args < <(build_gemini_command)

# Execute with timeout
if [[ "$quiet_mode" == true ]]; then
    output=$(timeout "$timeout_seconds" gemini "${cmd_args[@]}" 2>/dev/null) || exit_code=$?
else
    output=$(timeout "$timeout_seconds" gemini "${cmd_args[@]}" 2>&1) || exit_code=$?
fi

exit_code=${exit_code:-0}

# Handle timeout
if [[ $exit_code -eq 124 ]]; then
    log_error "TIMEOUT: Gemini did not complete within $timeout_minutes minutes."
    log_error "Options: 1) Increase timeout  2) Break into smaller tasks  3) Ask user"
    exit $EXIT_TIMEOUT
fi

# Check for workspace errors
if ! check_workspace_errors "$output" "$work_dir"; then
    exit 2
fi

# Output result
echo "$output"
exit $exit_code
