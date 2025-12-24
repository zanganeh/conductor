# Gemini Manager Workflows

Detailed workflow patterns for the manager/architect role.

## Example: Implementing a New Feature

### Scenario
User asks: "Add a user authentication system to my Express app"

### Manager Workflow

**Step 1: Reconnaissance**
```
Read package.json           # Understand dependencies
Glob **/routes/*.js         # Find existing routes
Grep "app.use\|router" .    # Understand routing structure
Read src/app.js             # Main entry point
```

**Step 2: Planning (Internal)**
Determine the implementation order:
1. Install dependencies (bcrypt, jsonwebtoken)
2. Create user model
3. Create auth routes (register, login)
4. Create auth middleware
5. Protect existing routes

**Step 3: Delegate - Install Dependencies**
```bash
gemini "Run: npm install bcrypt jsonwebtoken

Then update package.json to include these as production dependencies.

Execute now." --yolo -o text 2>&1
```

**Step 4: Verify**
```
Read package.json           # Check dependencies added
```

**Step 5: Delegate - Create User Model**
```bash
gemini "Create a User model in src/models/user.js

Requirements:
- Use mongoose schema
- Fields: email (unique, required), password (hashed), createdAt
- Pre-save hook to hash password with bcrypt
- Method to compare passwords

Create the file now." --yolo -o text 2>&1
```

**Step 6: Verify**
```
Read src/models/user.js     # Check implementation
Grep "bcrypt" src/models/   # Ensure hashing is used
```

**Continue pattern for each component...**

## Example: Fixing a Bug

### Scenario
User reports: "The login endpoint returns 500 error when email doesn't exist"

### Manager Workflow

**Step 1: Understand the Bug**
```
Read src/routes/auth.js     # Find login route
Grep "login\|findOne" .     # Trace the flow
```

**Step 2: Identify Root Cause**
(After reading) - The code assumes user exists and accesses user.password without null check.

**Step 3: Delegate Fix**
```bash
gemini "Fix bug in src/routes/auth.js login route.

Problem: No null check after User.findOne(). When user doesn't exist, accessing user.password throws error.

Solution: Add check for null user and return 401 with 'Invalid credentials' message.

Apply fix now." --yolo -o text 2>&1
```

**Step 4: Verify Fix**
```
Read src/routes/auth.js     # Check the fix
Grep "if.*user.*null\|if.*!user" src/routes/auth.js   # Verify null check exists
```

**Step 5: Request Test**
```bash
gemini "Run the auth tests to verify the login fix works.

Command: npm test -- --grep 'login'

Report the results." -o text 2>&1
```

## Example: Refactoring

### Scenario
User wants: "Extract the database connection logic into a separate module"

### Manager Workflow

**Step 1: Find Current Implementation**
```
Grep "mongoose.connect\|createConnection" .
Read src/app.js             # Find where connection happens
```

**Step 2: Delegate Extraction**
```bash
gemini "Refactor database connection in src/app.js.

Current: Connection logic is inline in app.js
Target: Create src/config/database.js that exports a connect function

Steps:
1. Create src/config/database.js with the connection logic
2. Export an async connect() function
3. Update src/app.js to import and call connect()
4. Maintain all existing environment variable usage

Apply changes now." --yolo -o text 2>&1
```

**Step 3: Verify Both Files**
```
Read src/config/database.js    # New module
Read src/app.js                # Updated import
```

**Step 4: Test Application Starts**
```bash
gemini "Start the application and verify it connects to the database.

Command: npm start

Report if connection succeeds." -o text 2>&1
```

## Verification Checklist

After each Gemini action, verify:

### For New Files
- [ ] File was created at correct path
- [ ] File has expected exports/structure
- [ ] No syntax errors
- [ ] Follows project conventions

### For Modifications
- [ ] Changes match the request
- [ ] No unintended side effects
- [ ] Existing functionality preserved
- [ ] Imports updated if needed

### For Deletions
- [ ] File removed
- [ ] References to deleted code updated
- [ ] No broken imports elsewhere

### For Bug Fixes
- [ ] Root cause addressed
- [ ] Fix doesn't introduce new bugs
- [ ] Edge cases handled
- [ ] Tests pass (if applicable)

## Escalation Patterns

### When Gemini Struggles

If Gemini produces incorrect output multiple times:

1. **Be more specific**
```bash
gemini "I need you to do EXACTLY this:

In file: src/utils/helper.js
At line: 42
Change: const result = data.map(x => x.id)
To: const result = data.filter(x => x.active).map(x => x.id)

Make this exact change now." --yolo -o text 2>&1
```

2. **Provide context**
```bash
gemini "Context you need:
- This is a React 18 app with TypeScript
- We use React Query for data fetching
- The component is functional, using hooks

Now implement [task]..." --yolo -o text 2>&1
```

3. **Break down further**
Instead of one complex task, issue multiple simple tasks.

### When Gemini Hits Limits

```bash
# Use faster model for simple tasks
gemini "[simple task]" -m gemini-2.5-flash --yolo -o text 2>&1

# Wait and retry for rate limits (Gemini auto-handles this)
```

## Complex Task Coordination

For large tasks spanning multiple files:

1. **Map out all files first**
```
Glob **/*.{js,ts,tsx}
```

2. **Create mental dependency order**
   - Models first (no dependencies)
   - Utilities second (depend on models)
   - Components third (depend on utilities)
   - Routes/Pages last (depend on components)

3. **Delegate in order with verification gates**
   - Complete models -> verify all models
   - Complete utilities -> verify all utilities
   - Continue pattern

4. **Final integration test**
```bash
gemini "Run the full test suite and the linter.

Commands:
- npm run lint
- npm test

Report all failures." -o text 2>&1
```

## Using the Helper Script

The `scripts/gemini-task.sh` script helps enforce timeouts and manages execution safety.

### Example: Quick Fix (Short Timeout)
For simple changes, use a short timeout (e.g., 2 minutes) to fail fast if Gemini gets stuck.

```bash
./scripts/gemini-task.sh -t 2 "Fix typo in README.md"
```

### Example: Heavy Implementation (Long Timeout)
For complex logic generation, allocate more time (max 10 minutes).

```bash
./scripts/gemini-task.sh -t 8 "Implement the full OAuth flow in auth.service.ts including error handling and retry logic."
```

### Example: Background Check
Run a check without cluttering stderr unless it fails.

```bash
./scripts/gemini-task.sh -q "Check if port 3000 is in use"
```
