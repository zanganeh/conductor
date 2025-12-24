#!/bin/bash
# Pre-flight check for AI Team Plugin
# Verifies all required tools are installed and configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "============================================"
echo "  AI Team Plugin - Pre-flight Check"
echo "============================================"
echo ""

# Function to check if command exists
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name found: $(command -v "$cmd")"
        return 0
    else
        echo -e "${RED}✗${NC} $name NOT FOUND"
        echo "  Install: $install_hint"
        ((ERRORS++))
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd=$1
    local name=$2
    local version_flag=$3

    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd $version_flag 2>&1 | head -1)
        echo "  Version: $version"
    fi
}

echo "=== Required Tools ==="
echo ""

# Check Gemini CLI
echo "Checking Gemini CLI..."
if check_command "gemini" "Gemini CLI" "npm install -g @anthropic-ai/claude-code"; then
    check_version "gemini" "Gemini" "--version"
fi
echo ""

# Check OpenCode CLI
echo "Checking OpenCode CLI..."
if check_command "opencode" "OpenCode CLI" "npm install -g opencode-ai"; then
    check_version "opencode" "OpenCode" "--version"
fi
echo ""

# Check Node.js (required for MCP)
echo "Checking Node.js..."
if check_command "node" "Node.js" "https://nodejs.org/"; then
    check_version "node" "Node.js" "--version"

    # Check Node version >= 18
    NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "  ${YELLOW}⚠${NC} Node.js 18+ recommended for Playwright MCP"
        ((WARNINGS++))
    fi
fi
echo ""

# Check npx (for Playwright MCP)
echo "Checking npx..."
check_command "npx" "npx" "Comes with Node.js"
echo ""

echo "=== Optional Tools ==="
echo ""

# Check Playwright MCP
echo "Checking Playwright MCP..."
if npx @playwright/mcp --help &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Playwright MCP available"
else
    echo -e "${YELLOW}⚠${NC} Playwright MCP not cached (will download on first use)"
    ((WARNINGS++))
fi
echo ""

echo "=== Configuration ==="
echo ""

# Check for config file
CONFIG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/ai-team-config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓${NC} Config file found: $CONFIG_FILE"
else
    echo -e "${YELLOW}⚠${NC} Config file not found: $CONFIG_FILE"
    echo "  Run: ai-team-init to create default config"
    ((WARNINGS++))
fi

# Check for learnings directory
LEARNINGS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/learnings"
if [ -d "$LEARNINGS_DIR" ]; then
    echo -e "${GREEN}✓${NC} Learnings directory exists"
else
    echo -e "${YELLOW}⚠${NC} Learnings directory not found"
    echo "  Run: ai-team-init to initialize"
    ((WARNINGS++))
fi
echo ""

echo "=== Environment ==="
echo ""

# Check CLAUDE_PROJECT_DIR
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    echo -e "${GREEN}✓${NC} CLAUDE_PROJECT_DIR: $CLAUDE_PROJECT_DIR"
else
    echo -e "${YELLOW}⚠${NC} CLAUDE_PROJECT_DIR not set (will use current directory)"
    ((WARNINGS++))
fi

# Check working directory
echo "  Current directory: $(pwd)"
echo ""

echo "============================================"
echo "  Summary"
echo "============================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Ready to use /ai:work${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}$WARNINGS warning(s) - Plugin will work but some features may be limited${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s) - Please fix errors before using /ai:work${NC}"
    exit 1
fi
