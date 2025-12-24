<#
.SYNOPSIS
    Initialize AI Team Plugin for a project

.DESCRIPTION
    Creates configuration files and directory structure for the AI Team Plugin
#>

$ProjectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
$ConfigDir = Join-Path $ProjectDir ".claude"
$ConfigFile = Join-Path $ConfigDir "ai-team-config.yaml"
$LearningsDir = Join-Path $ConfigDir "learnings"

Write-Host "============================================"
Write-Host "  AI Team Plugin - Initialization"
Write-Host "============================================"
Write-Host ""
Write-Host "Project directory: $ProjectDir"
Write-Host ""

# Create .claude directory
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
Write-Host "✓ Created: $ConfigDir" -ForegroundColor Green

# Create config file if not exists
if (-not (Test-Path $ConfigFile)) {
    $configContent = @'
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
'@
    $configContent | Out-File -FilePath $ConfigFile -Encoding UTF8
    Write-Host "✓ Created: $ConfigFile" -ForegroundColor Green
} else {
    Write-Host "⚠ Config already exists: $ConfigFile" -ForegroundColor Yellow
}

# Create learnings directory structure
New-Item -ItemType Directory -Force -Path "$LearningsDir\sessions\archive" | Out-Null
New-Item -ItemType Directory -Force -Path "$LearningsDir\agents" | Out-Null
Write-Host "✓ Created: $LearningsDir" -ForegroundColor Green

# Create patterns file
$patternsFile = Join-Path $LearningsDir "patterns.yaml"
if (-not (Test-Path $patternsFile)) {
    "# Effective patterns learned from past tasks`npatterns: []" | Out-File -FilePath $patternsFile -Encoding UTF8
    Write-Host "✓ Created: patterns.yaml" -ForegroundColor Green
}

# Create errors file
$errorsFile = Join-Path $LearningsDir "errors.yaml"
if (-not (Test-Path $errorsFile)) {
    "# Error patterns to avoid`nerrors: []" | Out-File -FilePath $errorsFile -Encoding UTF8
    Write-Host "✓ Created: errors.yaml" -ForegroundColor Green
}

# Create agent-specific files
foreach ($agent in @("gemini", "opencode")) {
    $agentFile = Join-Path $LearningsDir "agents\$agent.yaml"
    if (-not (Test-Path $agentFile)) {
        "# Learnings specific to $agent`nagent: $agent`neffective_prompts: []`nineffective_prompts: []" | Out-File -FilePath $agentFile -Encoding UTF8
        Write-Host "✓ Created: agents\$agent.yaml" -ForegroundColor Green
    }
}

# Create logs directory
New-Item -ItemType Directory -Force -Path "$ConfigDir\logs" | Out-Null
Write-Host "✓ Created: logs directory" -ForegroundColor Green

Write-Host ""
Write-Host "============================================"
Write-Host "  Initialization Complete!"
Write-Host "============================================"
Write-Host ""
Write-Host "Configuration file: $ConfigFile"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Edit $ConfigFile to customize models"
Write-Host "2. Run pre-flight check: .\scripts\preflight.ps1"
Write-Host "3. Start working: /ai:work <your task>"
Write-Host ""
