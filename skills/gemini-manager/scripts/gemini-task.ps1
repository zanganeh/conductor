<#
.SYNOPSIS
    Delegates a coding task to Gemini CLI (the Builder AI).

.DESCRIPTION
    This script is used by Claude (Conductor) to delegate implementation work to Gemini.
    Gemini runs in --yolo mode to automatically apply changes without confirmation.

    IMPORTANT: This script is for DELEGATION only. Claude should NEVER do the work itself.

.PARAMETER Prompt
    The implementation task to delegate to Gemini.

.PARAMETER LLM
    Which Gemini model to use (optional).

.PARAMETER MaxMinutes
    How long to wait before timing out (1-10 minutes, default: 5).

.PARAMETER Silent
    Hide stderr output from Gemini.

.PARAMETER ExtraPaths
    Additional directories Gemini can access (comma-separated).

.EXAMPLE
    .\gemini-task.ps1 "Create a responsive navbar component"

.EXAMPLE
    .\gemini-task.ps1 -MaxMinutes 8 -LLM "gemini-2.5-pro" "Refactor the auth module"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $false)]
    [string]$Prompt,

    [Alias("model", "m")]
    [string]$LLM,

    [Alias("timeout", "t")]
    [ValidateRange(1, 10)]
    [int]$MaxMinutes = 5,

    [Alias("quiet", "q")]
    [switch]$Silent,

    [Alias("include", "i")]
    [string[]]$ExtraPaths
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:ExecutableName = "gemini"
$Script:MaxAllowedMinutes = 10
$Script:ExitCodeTimeout = 124

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

GEMINI TASK DELEGATOR
=====================
Delegates implementation work from Claude (Conductor) to Gemini (Builder).

Usage:
    .\gemini-task.ps1 [options] "task description"
    "task" | .\gemini-task.ps1 [options]

Options:
    -LLM, -model, -m      Gemini model to use
    -MaxMinutes, -t       Timeout in minutes (default: 5, max: 10)
    -Silent, -quiet, -q   Suppress stderr output
    -ExtraPaths, -i       Additional workspace directories

Examples:
    .\gemini-task.ps1 "Build a login form with validation"
    .\gemini-task.ps1 -MaxMinutes 8 "Implement full CRUD for users"
    .\gemini-task.ps1 -ExtraPaths "C:\shared\lib" "Use shared utilities"

"@
}

function Build-GeminiArguments {
    param([string]$TaskPrompt, [string]$Model, [string[]]$IncludeDirs)

    $args = @("--yolo", "-o", "text")

    if ($Model) {
        $args += @("--model", $Model)
    }

    foreach ($dir in $IncludeDirs) {
        if ($dir) {
            $args += @("--include-directories", $dir)
        }
    }

    $args += $TaskPrompt
    return $args
}

function Invoke-GeminiWithTimeout {
    param(
        [string[]]$Arguments,
        [string]$WorkDir,
        [int]$TimeoutSeconds,
        [bool]$SuppressStderr
    )

    $jobScript = {
        param($cmdArgs, $suppressErr, $directory)
        Set-Location $directory
        if ($suppressErr) {
            & gemini @cmdArgs 2>$null
        } else {
            & gemini @cmdArgs 2>&1
        }
    }

    $job = Start-Job -ScriptBlock $jobScript -ArgumentList @(,$Arguments), $SuppressStderr, $WorkDir
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

function Test-WorkspaceErrors {
    param([string]$OutputText, [string]$Workspace)

    if ($OutputText -match "must be within one of the workspace directories") {
        Write-Error "WORKSPACE RESTRICTION: Gemini cannot write outside: $Workspace"
        Write-Error "Use -ExtraPaths to include additional directories."
        return $true
    }

    if ($OutputText -match "File path must be within") {
        Write-Warning "PATH REWRITE DETECTED: Gemini may have changed the target location."
        Write-Warning "Verify output files are in expected location: $Workspace"
    }

    return $false
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
    Write-Error "No task provided. Cannot delegate to Gemini without instructions."
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
$cmdArgs = Build-GeminiArguments -TaskPrompt $Prompt -Model $LLM -IncludeDirs $ExtraPaths
$timeoutSec = $MaxMinutes * 60

Write-Verbose "Delegating to Gemini in: $workDir"
Write-Verbose "Timeout: $MaxMinutes minutes"

# Execute
try {
    $result = Invoke-GeminiWithTimeout `
        -Arguments $cmdArgs `
        -WorkDir $workDir `
        -TimeoutSeconds $timeoutSec `
        -SuppressStderr $Silent

    if ($result.TimedOut) {
        Write-Error "TIMEOUT: Gemini did not complete within $MaxMinutes minutes."
        Write-Error "Consider breaking the task into smaller pieces or increasing timeout."
        exit $Script:ExitCodeTimeout
    }

    $outputText = $result.Output | Out-String

    if (Test-WorkspaceErrors -OutputText $outputText -Workspace $workDir) {
        exit 2
    }

    if ($result.Output) {
        Write-Output $result.Output
    }

    exit $result.ExitCode

} catch {
    Write-Error "Failed to execute Gemini: $_"
    exit 1
}
