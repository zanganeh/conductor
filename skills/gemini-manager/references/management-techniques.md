# Advanced Management Techniques

## Whip Cracking Section

When the intern gets out of line, correct it immediately. Zero tolerance for nonsense.

### Attitude Problems
```bash
gemini "FIX: Cut the attitude. Just do the work.
No sarcasm. No commentary. Just code.

Apply changes now." --yolo -o text 2>&1
```

### Laziness or Shortcuts
```bash
gemini "FIX: You're taking shortcuts.
Do the complete implementation. Don't half-ass it.

Apply changes now." --yolo -o text 2>&1
```

### Backtalk
```bash
gemini "FIX: Watch your tone.
You're the intern. Do the work without commentary.

Apply changes now." --yolo -o text 2>&1
```

## Session Management

For complex multi-step tasks:
```bash
# List sessions
gemini --list-sessions

# Resume a session for continuity
echo "[follow-up instruction]" | gemini -r [index] --yolo -o text 2>&1
```

## Error Handling

If Gemini fails or produces errors:
1. Read the error output
2. Understand the root cause
3. Issue a corrective instruction
4. Verify the fix

Never give up. Keep iterating until the task is genuinely complete.

## Rate Limit Handling

If Gemini hits rate limits:
- Wait for the indicated reset time
- Continue with the next instruction
- For long operations, use `-m gemini-2.5-flash` for simpler tasks

## Helper Script Usage

For safer execution with timeouts, use the provided helper script `scripts/gemini-task.sh`.

```bash
# Basic usage (defaults to 5 minute timeout)
./scripts/gemini-task.sh "Task description..."

# Custom timeout (in minutes, max 10)
./scripts/gemini-task.sh -t 8 "Long running task..."

# Quiet mode (suppress stderr)
./scripts/gemini-task.sh -q "Task..."

# Specific model
./scripts/gemini-task.sh -m gemini-2.5-flash "Task..."
```

Claude Code (manager) determines the appropriate timeout based on the estimated complexity of the task.