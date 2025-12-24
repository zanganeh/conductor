# Command Templates for Gemini Manager

## Delegation Templates

### Initial Implementation
```bash
gemini "Implement [feature] in [file].
Requirements:
1. [requirement 1]
2. [requirement 2]

Apply changes now." --yolo -o text 2>&1
```

### Bug Fix
```bash
gemini "Fix bug in [file] at line [N].
Current behavior: [what happens]
Expected behavior: [what should happen]

Apply fix immediately." --yolo -o text 2>&1
```

### Refactoring
```bash
gemini "Refactor [component] in [file].
Goal: [objective]
Constraints: [any constraints]

Apply refactoring now." --yolo -o text 2>&1
```

### Test Creation
```bash
gemini "Create tests for [file/function].
Framework: [jest/pytest/etc]
Coverage requirements: [what to test]

Write tests now." --yolo -o text 2>&1
```

## Fix Templates

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

### Over-Engineering
```bash
gemini "FIX: You are over-engineering this.
Remove the factory pattern and just use a simple function.
Keep it simple.

Apply changes now." --yolo -o text 2>&1
```