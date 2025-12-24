<#
.SYNOPSIS
    Pre-flight check for AI Team Plugin

.DESCRIPTION
    Verifies all required tools are installed and configured before using /ai:work
#>

$Errors = 0
$Warnings = 0

function Write-Check {
    param([string]$Status, [string]$Message)

    switch ($Status) {
        "pass" { Write-Host "✓ " -ForegroundColor Green -NoNewline; Write-Host $Message }
        "fail" { Write-Host "✗ " -ForegroundColor Red -NoNewline; Write-Host $Message }
        "warn" { Write-Host "⚠ " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
    }
}

function Test-Command {
    param(
        [string]$Command,
        [string]$Name,
        [string]$InstallHint
    )

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Check "pass" "$Name found: $($cmd.Source)"
        return $true
    } else {
        Write-Check "fail" "$Name NOT FOUND"
        Write-Host "  Install: $InstallHint"
        $script:Errors++
        return $false
    }
}

function Get-ToolVersion {
    param([string]$Command, [string]$Flag)

    try {
        $version = & $Command $Flag 2>&1 | Select-Object -First 1
        Write-Host "  Version: $version"
    } catch {}
}

Write-Host "============================================"
Write-Host "  AI Team Plugin - Pre-flight Check"
Write-Host "============================================"
Write-Host ""

Write-Host "=== Required Tools ===" -ForegroundColor Cyan
Write-Host ""

# Check Gemini CLI
Write-Host "Checking Gemini CLI..."
if (Test-Command "gemini" "Gemini CLI" "npm install -g @google/generative-ai-cli") {
    Get-ToolVersion "gemini" "--version"
}
Write-Host ""

# Check OpenCode CLI
Write-Host "Checking OpenCode CLI..."
if (Test-Command "opencode" "OpenCode CLI" "npm install -g opencode-ai") {
    Get-ToolVersion "opencode" "--version"
}
Write-Host ""

# Check Node.js
Write-Host "Checking Node.js..."
if (Test-Command "node" "Node.js" "https://nodejs.org/") {
    Get-ToolVersion "node" "--version"

    $nodeVersion = (node --version) -replace 'v', '' -split '\.' | Select-Object -First 1
    if ([int]$nodeVersion -lt 18) {
        Write-Check "warn" "Node.js 18+ recommended for Playwright MCP"
        $Warnings++
    }
}
Write-Host ""

# Check npx
Write-Host "Checking npx..."
Test-Command "npx" "npx" "Comes with Node.js" | Out-Null
Write-Host ""

Write-Host "=== Optional Tools ===" -ForegroundColor Cyan
Write-Host ""

# Check Playwright MCP
Write-Host "Checking Playwright MCP..."
try {
    $null = npx @playwright/mcp --help 2>&1
    Write-Check "pass" "Playwright MCP available"
} catch {
    Write-Check "warn" "Playwright MCP not cached (will download on first use)"
    $Warnings++
}
Write-Host ""

Write-Host "=== Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Check for config file
$ProjectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
$ConfigFile = Join-Path $ProjectDir ".claude\ai-team-config.yaml"

if (Test-Path $ConfigFile) {
    Write-Check "pass" "Config file found: $ConfigFile"
} else {
    Write-Check "warn" "Config file not found: $ConfigFile"
    Write-Host "  Run: ai-team-init to create default config"
    $Warnings++
}

# Check learnings directory
$LearningsDir = Join-Path $ProjectDir ".claude\learnings"
if (Test-Path $LearningsDir) {
    Write-Check "pass" "Learnings directory exists"
} else {
    Write-Check "warn" "Learnings directory not found"
    Write-Host "  Run: ai-team-init to initialize"
    $Warnings++
}
Write-Host ""

Write-Host "=== Environment ===" -ForegroundColor Cyan
Write-Host ""

if ($env:CLAUDE_PROJECT_DIR) {
    Write-Check "pass" "CLAUDE_PROJECT_DIR: $env:CLAUDE_PROJECT_DIR"
} else {
    Write-Check "warn" "CLAUDE_PROJECT_DIR not set (will use current directory)"
    $Warnings++
}

Write-Host "  Current directory: $(Get-Location)"
Write-Host ""

Write-Host "============================================"
Write-Host "  Summary"
Write-Host "============================================"
Write-Host ""

if ($Errors -eq 0 -and $Warnings -eq 0) {
    Write-Host "All checks passed! Ready to use /ai:work" -ForegroundColor Green
    exit 0
} elseif ($Errors -eq 0) {
    Write-Host "$Warnings warning(s) - Plugin will work but some features may be limited" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "$Errors error(s), $Warnings warning(s) - Please fix errors before using /ai:work" -ForegroundColor Red
    exit 1
}
