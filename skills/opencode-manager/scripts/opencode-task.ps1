<#
.SYNOPSIS
    Delegates a QA/testing task to OpenCode CLI (the Tester AI).

.DESCRIPTION
    This script is used by Claude (Conductor) to delegate testing work to OpenCode.
    OpenCode uses GLM-4.7 to run browser-based QA tests and report issues.

    IMPORTANT: This script is for DELEGATION only. Claude should NEVER run tests itself,
    even if OpenCode is slow or unresponsive. Wait, retry, or ask the user.

.PARAMETER Prompt
    The testing task to delegate to OpenCode.

.PARAMETER LLM
    Which model to use (default: opencode/glm-4.7-free).

.PARAMETER MaxMinutes
    How long to wait before timing out (1-10 minutes, default: 5).

.PARAMETER Mode
    Agent mode: 'build' for implementation, 'plan' for analysis (default: build).

.PARAMETER Attachments
    Files to include with the task.

.EXAMPLE
    .\opencode-task.ps1 "Test the login form at http://localhost:3000/login"

.EXAMPLE
    .\opencode-task.ps1 -MaxMinutes 8 "Run full QA suite on the dashboard"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $false)]
    [string]$Prompt,

    [Alias("model", "m")]
    [string]$LLM = "opencode/glm-4.7-free",

    [Alias("timeout", "t")]
    [ValidateRange(1, 10)]
    [int]$MaxMinutes = 5,

    [Alias("agent", "a")]
    [ValidateSet("build", "plan")]
    [string]$Mode = "build",

    [Alias("files", "f")]
    [string[]]$Attachments
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:ExecutableName = "opencode"
$Script:MaxAllowedMinutes = 10
$Script:ExitCodeTimeout = 124
$Script:DefaultModel = "opencode/glm-4.7-free"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-WorkingDirectory {
    if ($env:CLAUDE_PROJECT_DIR -and (Test-Path $env:CLAUDE_PROJECT_DIR)) {
        return $env:CLAUDE_PROJECT_DIR
    }
    Write-Warning "CLAUDE_PROJECT_DIR not set or invalid. Falling back to current directory."
    return (Get-Location).Path
}

function Show-Usage {
    Write-Host @"

OPENCODE QA DELEGATOR
=====================
Delegates QA/testing work from Claude (Conductor) to OpenCode (Tester).

REMINDER: If OpenCode is slow, DO NOT take over testing yourself.
          Wait longer, retry, or ask the user for guidance.

Usage:
    .\opencode-task.ps1 [options] "test description"
    "test task" | .\opencode-task.ps1 [options]

Options:
    -LLM, -model, -m       Model to use (default: opencode/glm-4.7-free)
    -MaxMinutes, -t        Timeout in minutes (default: 5, max: 10)
    -Mode, -agent, -a      Agent mode: build or plan (default: build)
    -Attachments, -f       Files to attach to the task

Examples:
    .\opencode-task.ps1 "Test login form validation"
    .\opencode-task.ps1 -MaxMinutes 8 "Full QA on checkout flow"
    .\opencode-task.ps1 -Mode plan "Analyze test coverage"

"@
}

function Build-OpenCodeArguments {
    param(
        [string]$TaskPrompt,
        [string]$Model,
        [string]$AgentMode,
        [string[]]$Files
    )

    $args = @("run", "--model", $Model, "--agent", $AgentMode)

    foreach ($file in $Files) {
        if ($file) {
            $args += @("--file", $file)
        }
    }

    $args += $TaskPrompt
    return $args
}

function Invoke-OpenCodeWithTimeout {
    param(
        [string[]]$Arguments,
        [string]$WorkDir,
        [int]$TimeoutSeconds
    )

    $jobScript = {
        param($cmdArgs, $directory)
        Set-Location $directory
        & opencode @cmdArgs 2>&1
    }

    $job = Start-Job -ScriptBlock $jobScript -ArgumentList @(,$Arguments), $WorkDir
    $finished = Wait-Job -Job $job -Timeout $TimeoutSeconds

    if ($null -eq $finished) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        return @{ TimedOut = $true; Output = $null; ExitCode = $Script:ExitCodeTimeout }
    }

    $result = Receive-Job -Job $job
    $code = if ($job.State -eq 'Completed') { 0 } else { 1 }
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

    return @{ TimedOut = $false; Output = $result; ExitCode = $code }
}

function Test-OutputForIssues {
    param([string]$OutputText)

    if ($OutputText -match "(?i)(error|failed|exception)") {
        Write-Warning "OpenCode reported potential issues. Review the output carefully."
        Write-Warning "If tests failed, delegate fixes to Gemini - do NOT fix them yourself."
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Handle piped input
if (-not $Prompt -and $MyInvocation.ExpectingInput) {
    $Prompt = ($input | Out-String).Trim()
}

# Validate we have a task
if ([string]::IsNullOrWhiteSpace($Prompt)) {
    Write-Error "No test task provided. Cannot delegate to OpenCode without instructions."
    Show-Usage
    exit 1
}

# Cap timeout at maximum
if ($MaxMinutes -gt $Script:MaxAllowedMinutes) {
    Write-Warning "Timeout $MaxMinutes exceeds max ($Script:MaxAllowedMinutes). Using maximum."
    $MaxMinutes = $Script:MaxAllowedMinutes
}

# Setup
$workDir = Get-WorkingDirectory
$cmdArgs = Build-OpenCodeArguments -TaskPrompt $Prompt -Model $LLM -AgentMode $Mode -Files $Attachments
$timeoutSec = $MaxMinutes * 60

Write-Verbose "Delegating QA to OpenCode in: $workDir"
Write-Verbose "Model: $LLM | Mode: $Mode | Timeout: $MaxMinutes min"

# Execute
try {
    $result = Invoke-OpenCodeWithTimeout `
        -Arguments $cmdArgs `
        -WorkDir $workDir `
        -TimeoutSeconds $timeoutSec

    if ($result.TimedOut) {
        Write-Error "TIMEOUT: OpenCode did not complete within $MaxMinutes minutes."
        Write-Error "Options: 1) Increase timeout  2) Simplify task  3) Ask user"
        Write-Error "DO NOT take over and run tests yourself!"
        exit $Script:ExitCodeTimeout
    }

    $outputText = $result.Output | Out-String
    Test-OutputForIssues -OutputText $outputText

    if ($result.Output) {
        Write-Output $result.Output
    }

    exit $result.ExitCode

} catch {
    Write-Error "Failed to execute OpenCode: $_"
    Write-Error "If this persists, ask the user for guidance. Do NOT run tests yourself."
    exit 1
}
