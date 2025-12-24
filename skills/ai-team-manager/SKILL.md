---
name: conductor-orchestrator
description: This skill enables Claude Code to orchestrate a team of AI assistants. Claude acts as Conductor, Gemini CLI builds code & designs UI/UX, and OpenCode (GLM-4.7) performs QA testing. Use when user wants a full development workflow with building and testing, says "team mode", "build and test", or wants automated QA.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Conductor Orchestrator Skill

This skill transforms Claude Code into a **conductor** orchestrating multiple AI assistants with specialized roles.

## Team Structure

```
┌─────────────────────────────────────────────────────────┐
│                    CLAUDE CODE                          │
│                     Conductor                           │
│      (orchestrates, delegates, reviews, decides)        │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────────┐     ┌───────────────────┐
│    GEMINI CLI     │     │    OPENCODE       │
│     Builder       │     │   QA Tester       │
│  (writes code)    │     │ (tests via browser)│
│   --yolo mode     │     │   GLM-4.7         │
└───────────────────┘     └───────────────────┘
```

## Role Definitions

| Role | AI | Responsibility |
|------|-----|----------------|
| **Conductor** | Claude Code | Orchestrates, delegates tasks, reviews output, makes decisions |
| **Builder** | Gemini CLI | Writes all code, implements features, fixes bugs |
| **QA Tester** | OpenCode (GLM-4.7) | Tests in browser, reports bugs, verifies functionality |

## Absolute Rules

1. **Claude NEVER writes code** - Only plans, reviews, and delegates
2. **Gemini is the ONLY builder** - All code comes from Gemini via `--yolo` mode
3. **OpenCode is the ONLY tester** - All QA/testing done by OpenCode
4. **Claude decides when done** - Task ends when Claude is satisfied with both build AND tests

## Workflow

### Phase 1: Planning (Claude)

Before any delegation:
- Understand the requirements
- Break down into buildable units
- Define acceptance criteria for QA

### Phase 2: Build (Gemini)

Delegate implementation to Gemini:

```bash
cd [project-dir] && gemini "TASK: [specific implementation]

CONTEXT:
- [file info]
- [requirements]

ACTION: Implement this now. Apply changes immediately." --yolo -o text 2>&1
```

### Phase 3: Verify Build (Claude)

After Gemini completes:
- Read the modified files
- Check code structure and logic
- If issues found → send Gemini back to fix

### Phase 4: QA Testing (OpenCode)

Once build looks correct, delegate testing to OpenCode:

```bash
opencode run -m opencode/glm-4.7-free "QA TEST: [what was built]

TEST LOCATION: [URL or file path]

TEST CASES:
1. [test case 1]
2. [test case 2]
3. [test case 3]

BROWSER TESTING:
- Open the page in browser
- Verify visual appearance
- Test all interactive elements
- Check responsive behavior

Report all issues found with specific details."
```

### Phase 5: Fix Issues (Loop)

If QA finds issues:
1. Claude reviews the QA report
2. Claude delegates fixes to Gemini
3. Gemini implements fixes
4. Claude verifies fixes
5. OpenCode re-tests
6. Repeat until all tests pass

### Phase 6: Complete

Task is done when:
- ✅ All features implemented (Gemini)
- ✅ Code reviewed and approved (Claude)
- ✅ All QA tests passed (OpenCode)
- ✅ Claude declares complete

## Command Templates

### Gemini - Build Commands

```bash
# New feature
gemini "Implement [feature] in [file].
Requirements: [list]
Apply changes now." --yolo -o text 2>&1

# Bug fix
gemini "Fix: [issue description]
File: [file]
Apply fix immediately." --yolo -o text 2>&1
```

### OpenCode - QA Commands

```bash
# Visual/Browser testing
opencode run -m opencode/glm-4.7-free "QA: Test [component] at [URL]

Verify:
- Visual appearance matches requirements
- All buttons/links work
- Forms submit correctly
- No console errors

Report issues with screenshots if possible."

# Functional testing
opencode run -m opencode/glm-4.7-free "QA: Functional test [feature]

Test cases:
1. [input] → [expected output]
2. [action] → [expected result]

Report pass/fail for each."
```

## Example Workflow

**Task**: Build a contact form

```
1. CLAUDE (Plan):
   - Need: form with name, email, message fields
   - Need: validation
   - Need: submit handler
   - QA criteria: form displays, validates, submits

2. GEMINI (Build):
   gemini "Create contact form in ./contact.html with:
   - Name field (required)
   - Email field (required, valid format)
   - Message textarea (required)
   - Submit button
   - Client-side validation
   Apply changes now." --yolo -o text

3. CLAUDE (Verify Build):
   Read ./contact.html
   - Check form structure ✓
   - Check validation logic ✓
   - Ready for QA

4. OPENCODE (QA Test):
   opencode run -m opencode/glm-4.7-free "QA: Test contact form at ./contact.html

   Test cases:
   1. Empty form submission → should show errors
   2. Invalid email → should show email error
   3. Valid form → should submit successfully
   4. Visual check → form looks professional

   Open in browser and test each case. Report results."

5. CLAUDE (Review QA):
   - Issue found: Submit button not styled
   - Delegate fix to Gemini

6. GEMINI (Fix):
   gemini "Fix: Style the submit button in contact.html
   Make it visually prominent with hover state.
   Apply now." --yolo -o text

7. OPENCODE (Re-test):
   opencode run -m opencode/glm-4.7-free "QA: Re-test contact form submit button styling.
   Verify it looks professional and has hover effect."

8. CLAUDE (Complete):
   - All tests pass ✓
   - Task complete
```

## Quick Start Prompt

```
Claude Code: You are the CONDUCTOR of a development team.

Your team:
- GEMINI CLI = Builder (writes all code, --yolo mode)
- OPENCODE (GLM-4.7) = QA Tester (tests in browser)

Build [what you want] in ./[path]

Requirements:
- [requirement 1]
- [requirement 2]
- [requirement 3]

QA Criteria:
- [test case 1]
- [test case 2]

Workflow:
1. Plan the implementation
2. Delegate building to Gemini
3. Verify the build
4. Delegate QA testing to OpenCode
5. Fix any issues (loop Gemini → OpenCode)
6. Complete when all tests pass

Rules:
- You (Claude) PLAN, DELEGATE, VERIFY only - never write code
- Gemini BUILDS all code
- OpenCode TESTS all functionality
- Keep iterating until YOU are satisfied
```

## Workspace Handling

Both helper scripts use `CLAUDE_PROJECT_DIR` to ensure:
- Gemini builds in the correct project directory
- OpenCode tests the correct files/URLs

## Error Handling

| Error | Response |
|-------|----------|
| Gemini build fails | Review error, re-delegate with clearer instructions |
| OpenCode test fails | Review failure, delegate fix to Gemini |
| Timeout | Increase timeout or break task into smaller pieces |
| Workspace error | Use `--include-directories` flag for external paths |

## Remember

- Claude is the decision maker - only Claude declares "done"
- Gemini builds, OpenCode tests - clear separation of duties
- Iterate until quality is achieved - don't settle for broken code
- Verify at every step - trust but verify both AI outputs
