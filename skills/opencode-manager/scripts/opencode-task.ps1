<#
.SYNOPSIS
    Wrapper script for OpenCode CLI with timeout and options.

.DESCRIPTION
    Executes OpenCode CLI in non-interactive mode with configurable timeout, model selection, and output format.
    Automatically runs in the user's project directory (CLAUDE_PROJECT_DIR), not the plugin directory.

.PARAMETER Task
    The task description/prompt for OpenCode.

.PARAMETER Model
    Specify the model to use in provider/model format (default: opencode/glm-4.7-free).

.PARAMETER TimeoutMinutes
    Timeout in minutes (default: 5, max: 10).

.PARAMETER Agent
    Agent to use (build or plan).

.PARAMETER Files
    Files to attach to the message.

.EXAMPLE
    .\opencode-task.ps1 "Implement a login form"

.EXAMPLE
    .\opencode-task.ps1 -TimeoutMinutes 8 -Model "opencode/glm-4.7-free" "Fix the bug"

.EXAMPLE
    .\opencode-task.ps1 -Agent plan "Analyze this codebase"
#>

param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [string]$Task,

    [Alias("m")]
    [string]$Model = "opencode/glm-4.7-free",

    [Alias("t")]
    [ValidateRange(1, 10)]
    [int]$TimeoutMinutes = 5,

    [Alias("a")]
    [ValidateSet("build", "plan")]
    [string]$Agent = "build",

    [Alias("f")]
    [string[]]$Files
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
    Write-Host "Usage: .\opencode-task.ps1 [-Model model] [-Agent agent] [-TimeoutMinutes minutes] [-Files files] [task_description]"
    Write-Host "  -Model, -m          : Model in provider/model format (default: opencode/glm-4.7-free)"
    Write-Host "  -Agent, -a          : Agent to use: build or plan (default: build)"
    Write-Host "  -TimeoutMinutes, -t : Timeout in minutes (default: 5, max: 10)"
    Write-Host "  -Files, -f          : Files to attach to message"
    Write-Host "  task_description    : The task prompt (can also be piped)"
    exit 1
}

# Build the opencode command arguments
# Using 'run' for non-interactive execution
$opencodeArgs = @("run")

# Add model
$opencodeArgs += "--model"
$opencodeArgs += $Model

# Add agent
$opencodeArgs += "--agent"
$opencodeArgs += $Agent

# Add files if specified
if ($Files) {
    foreach ($file in $Files) {
        $opencodeArgs += "--file"
        $opencodeArgs += $file
    }
}

# Add the task as the message
$opencodeArgs += $Task

# Use project directory as workspace
$Workspace = $ProjectDir

# Convert timeout to seconds
$TimeoutSeconds = $TimeoutMinutes * 60

try {
    # Create a job to run opencode with timeout in the project directory
    $job = Start-Job -ScriptBlock {
        param($args, $workDir)
        Set-Location $workDir
        & opencode @args 2>&1
    } -ArgumentList @(, $opencodeArgs), $ProjectDir

    # Wait for job with timeout
    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds

    if ($null -eq $completed) {
        # Timeout occurred
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        Write-Error "Error: Operation timed out after $TimeoutMinutes minutes."
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

    # Check for common errors in output
    $outputStr = $output | Out-String
    if ($outputStr -match "error|failed|Error|Failed") {
        Write-Warning "OpenCode reported potential issues. Review output carefully."
    }

    # Print output
    if ($output) {
        Write-Output $output
    }

    exit $exitCode

} catch {
    Write-Error "Error executing opencode: $_"
    exit 1
}
