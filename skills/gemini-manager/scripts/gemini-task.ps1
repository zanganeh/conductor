<#
.SYNOPSIS
    Wrapper script for Gemini CLI with timeout and options.

.DESCRIPTION
    Executes Gemini CLI with configurable timeout, model selection, and quiet mode.
    Automatically runs in the user's project directory (CLAUDE_PROJECT_DIR), not the plugin directory.

.PARAMETER Task
    The task description/prompt for Gemini.

.PARAMETER Model
    Specify the model to use (optional).

.PARAMETER TimeoutMinutes
    Timeout in minutes (default: 5, max: 10).

.PARAMETER Quiet
    Suppress stderr output.

.PARAMETER IncludeDirectories
    Additional directories to include in Gemini's workspace (comma-separated).

.EXAMPLE
    .\gemini-task.ps1 "Implement a login form"

.EXAMPLE
    .\gemini-task.ps1 -TimeoutMinutes 8 -Model "gemini-2.5-flash" "Fix the bug"

.EXAMPLE
    .\gemini-task.ps1 -Quiet "Task description"

.EXAMPLE
    .\gemini-task.ps1 -IncludeDirectories "C:\other\path" "Create file in external dir"
#>

param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [string]$Task,

    [Alias("m")]
    [string]$Model,

    [Alias("t")]
    [ValidateRange(1, 10)]
    [int]$TimeoutMinutes = 5,

    [Alias("q")]
    [switch]$Quiet,

    [Alias("i")]
    [string[]]$IncludeDirectories
)

# Determine the working directory: use CLAUDE_PROJECT_DIR if available, otherwise current directory
$ProjectDir = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($ProjectDir)) {
    $ProjectDir = (Get-Location).Path
    Write-Warning "CLAUDE_PROJECT_DIR not set. Using current directory: $ProjectDir"
}

# Validate timeout and cap at 10
if ($TimeoutMinutes -gt 10) {
    Write-Warning "Timeout of $TimeoutMinutes minutes exceeds limit. Capping at 10 minutes."
    $TimeoutMinutes = 10
}

# Get task from pipeline if not provided as argument
if (-not $Task -and $MyInvocation.ExpectingInput) {
    $Task = $input | Out-String
}

# Validate task
if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-Error "Error: No task description provided."
    Write-Host "Usage: .\gemini-task.ps1 [-Model model] [-Quiet] [-TimeoutMinutes minutes] [-IncludeDirectories dirs] [task_description]"
    Write-Host "  -Model, -m             : Specify the model to use"
    Write-Host "  -Quiet, -q             : Quiet mode (suppress stderr)"
    Write-Host "  -TimeoutMinutes, -t    : Timeout in minutes (default: 5, max: 10)"
    Write-Host "  -IncludeDirectories, -i: Additional directories for Gemini workspace"
    Write-Host "  task_description       : The task prompt (can also be piped)"
    exit 1
}

# Build the gemini command arguments
$geminiArgs = @("--yolo", "-o", "text")

if ($Model) {
    $geminiArgs += "--model"
    $geminiArgs += $Model
}

# Add include-directories if specified
if ($IncludeDirectories) {
    foreach ($dir in $IncludeDirectories) {
        $geminiArgs += "--include-directories"
        $geminiArgs += $dir
    }
}

$geminiArgs += $Task

# Use project directory as workspace
$Workspace = $ProjectDir

# Convert timeout to seconds
$TimeoutSeconds = $TimeoutMinutes * 60

try {
    # Create a job to run gemini with timeout in the project directory
    $job = Start-Job -ScriptBlock {
        param($args, $quiet, $workDir)
        Set-Location $workDir
        if ($quiet) {
            & gemini @args 2>$null
        } else {
            & gemini @args 2>&1
        }
    } -ArgumentList @(, $geminiArgs), $Quiet, $ProjectDir

    # Wait for job with timeout
    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds

    if ($null -eq $completed) {
        # Timeout occurred
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        if (-not $Quiet) {
            Write-Error "Error: Operation timed out after $TimeoutMinutes minutes."
        }
        exit 124
    }

    # Get output and exit code
    $output = Receive-Job -Job $job
    $exitCode = $job.ChildJobs[0].JobStateInfo.Reason.ExitCode

    # If exit code is null, try to determine from job state
    if ($null -eq $exitCode) {
        $exitCode = if ($job.State -eq 'Completed') { 0 } else { 1 }
    }

    Remove-Job -Job $job -Force

    # Check for workspace restriction errors (Gemini silently rewrites paths)
    $outputStr = $output | Out-String
    if ($outputStr -match "must be within one of the workspace directories") {
        Write-Error "WORKSPACE ERROR: Gemini cannot write outside current workspace: $Workspace"
        Write-Error "Target path was silently rewritten. Change directory to target location first."
        exit 2
    }

    # Warn if output suggests path was rewritten (heuristic check)
    if ($outputStr -match "File path must be within") {
        Write-Warning "WORKSPACE WARNING: Gemini may have rewritten the target path."
        Write-Warning "Current workspace: $Workspace"
        Write-Warning "Verify files were created in the expected location."
    }

    # Print output
    if ($output) {
        Write-Output $output
    }

    exit $exitCode

} catch {
    Write-Error "Error executing gemini: $_"
    exit 1
}
