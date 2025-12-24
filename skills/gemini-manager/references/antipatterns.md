# Gemini Anti-Pattern Detection

As a manager, watch for these common mistakes from Gemini (the intern).

## 1. OVER-ENGINEERING
- **Symptoms**:
  - Adding unnecessary abstractions (factories, strategies) for simple logic.
  - Creating `utils/` or `helpers/` for code used only once.
  - Adding configuration options or features not requested.
  - Premature optimization (caching, complex algorithms) for simple tasks.
- **Guidance**: "Keep it simple. Implement exactly what was asked. YAGNI (You Ain't Gonna Need It)."

## 2. INCOMPLETE WORK
- **Symptoms**:
  - Leaving `TODO` comments without implementing the logic.
  - Partial implementations (e.g., function shells).
  - Missing error handling that was explicitly requested.
  - Forgetting to export new functions or import dependencies.
- **Guidance**: "Finish the task. All TODOs must be resolved before completion. Verify error paths."

## 3. EXCITEMENT SPRAWL
- **Symptoms**:
  - Modifying files not related to the current task.
  - Refactoring unrelated code 'while you are at it'.
  - Adding 'improvements' or 'cleanups' nobody asked for.
  - Scope creep: solving adjacent problems.
- **Guidance**: "Stay in scope. Only touch what is necessary for this specific request. Do not refactor unrelated code."

## 4. COPY-PASTE ERRORS
- **Symptoms**:
  - Duplicated code blocks with slight variations.
  - Inconsistent naming (camelCase mixed with snake_case).
  - Leftover placeholder text (e.g., `// Add logic here`, `foo`, `bar`).
  - Wrong variable names copied from other files/templates.
- **Guidance**: "Review your code. Check for copy-paste artifacts. Ensure naming consistency."

## 5. SECURITY BLINDSPOTS
- **Symptoms**:
  - Hardcoded secrets (API keys, passwords).
  - Missing input validation (trusting user input).
  - SQL injection or command injection vulnerabilities.
  - Exposing sensitive data in logs or error messages.
- **Guidance**: "Security first. Never hardcode secrets. Validate all inputs. Sanitize logs."

## 6. VERIFICATION COMMANDS
Use these patterns to quick-check Gemini's work:

### FOR OVER-ENGINEERING
- **Detect Complex Patterns**: `grep -rE "Factory|Builder|Strategy|Singleton" src/`
- **Check Utility Sprawl**: `find src/ -name "*util*" -o -name "*helper*" -o -name "*common*"`
- **Line Count Check**: `git diff --stat` (Is the change massive for a small request?)

### FOR INCOMPLETE WORK
- **Find Leftovers**: `grep -rnE "TODO|FIXME|XXX|HACK" .`
- **Find Generic Errors**: `grep -r "throw new Error" .` (Should be specific error types)
- **Empty Functions**: `grep -r "{}" .` (Review context for empty blocks)

### FOR EXCITEMENT SPRAWL
- **Check Changed Files**: `git diff --name-only` (Are these the files we agreed to change?)
- **Diff Stats**: `git diff --stat` (Review scope of changes)

### FOR COPY-PASTE ERRORS
- **Find Placeholders**: `grep -rnE "foo|bar|example|test123" .`
- **Duplicate Functions**: `grep -r "function" . | sort | uniq -d` (Rough check)
- **Naming Consistency**: Visually inspect `git diff` for mixed case (camelCase vs snake_case).

### FOR SECURITY
- **Find Secrets**: `grep -rnEi "password|secret|key|token" .` (Case insensitive)
- **Dangerous Calls**: `grep -rnE "eval\(|exec\(|system\(" .`
- **Unsanitized Queries**: `grep -r "\${" .` (Check SQL/Command strings for direct interpolation)
