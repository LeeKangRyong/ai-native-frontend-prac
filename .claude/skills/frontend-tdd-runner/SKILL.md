---
name: frontend-tdd-runner
description: >-
  TDD validation skill for this monorepo's four sub-apps (prac-fe-app-driver,
  prac-fe-app-user, prac-fe-web-manager, prac-fe-web-intro). Runs type check
  (tsc, mobile only) → unit tests (npm test) → E2E (Playwright, web only)
  in sequence. Two modes: (1) Validate-only — runs tests and reports
  pass/fail, no agent spawning; used as the pre-flight gate inside
  frontend-commit-push and for "테스트 돌려줘", "TDD 검증해줘", "commit 전에
  테스트", "run tests", "check tests". (2) Auto-fix — spawns a fix-agent
  per iteration to resolve failures automatically (unit max 3, E2E max 2);
  triggered by "테스트 고쳐줘", "테스트 통과시켜줘", "테스트 에러 고쳐줘",
  "unit test 실패 고쳐줘", "테스트 자동 수정", "fix tests". Always use this
  skill for any mention of running, fixing, or checking tests for any of the
  four sub-apps. Also called automatically inside frontend-commit-push.
---

# Frontend TDD Runner

## Role

Owns the full test gate for a specified sub-app. Runs tsc → unit tests → E2E in sequence, then cleans up zombie servers on completion. Its primary usage pattern is being called from Step 4 (pre-flight) of `frontend-commit-push`.

**Absolute rule**: When the fix-agent modifies code, it must only touch files inside the designated sub-app directory. Other sub-apps and root files are never modified.

---

## Environment Detection

Detect the shell environment once at invocation start and use it throughout all steps:

| Test | WSL / bash | Windows PowerShell / CMD |
|---|---|---|
| Detect shell | `uname -s` → `Linux` | `uname` not found, or `$IsWindows` is `$true` |
| Current dir name | `basename "$(pwd)"` | `Split-Path -Leaf (Get-Location)` |
| Kill port (WSL) | `fuser -k ${port}/tcp 2>/dev/null \|\| true` | — |
| Kill port (Win) | — | `netstat -ano \| findstr :${port}` → `taskkill /PID {pid} /F` |

---

## Mode Detection

Determine the mode from the invocation context **before running any steps**.

| Mode | When | Agent spawning |
|---|---|---|
| **Validate-only** | Called from `frontend-commit-push`, or utterance is about running/checking tests ("테스트 돌려줘", "TDD 검증해줘", "commit 전에 테스트", "run tests", "check tests") | None — tests run as bash commands only |
| **Auto-fix** | Utterance explicitly requests fixing ("테스트 고쳐줘", "테스트 통과시켜줘", "테스트 에러 고쳐줘", "unit test 실패 고쳐줘", "테스트 자동 수정", "fix tests") | Single fix-agent per loop iteration |

When the mode is ambiguous, default to **validate-only**.

---

## Dry-Run Mode

If the utterance contains `dry-run`, `확인만 해줘`, `실행 말고 보여줘`, or `미리 보기만`, operate in dry-run mode.

- **Step 0 (environment detection) runs for real** — reads package.json to determine sub-app type and Playwright installation.
- **Steps 1–3 (tsc, npm test, Playwright) and fix loops do not run.**
- Instead, output the list of commands that would run and the loop settings in the format below, then stop.

**Mobile app output example (prac-fe-app-user):**
```
[DRY-RUN] Not actually executing
Sub-app: prac-fe-app-user (mobile, Node 20)
─────────────────────────────────────────
Planned execution order:
  1. npx tsc --noEmit
     On failure → counts toward unit test loop iterations
  2. npm test -- --watchAll=false
     On failure: fix loop max 3 attempts: fix-agent → re-run
  3. E2E: SKIPPED (mobile app)
  4. Cleanup: kill ports 3000 3001 4000 5173 5174 8080
─────────────────────────────────────────
```

**Web app output example (prac-fe-web-manager):**
```
[DRY-RUN] Not actually executing
Sub-app: prac-fe-web-manager (web, Node 22)
─────────────────────────────────────────
Planned execution order:
  1. tsc: SKIPPED (web app)
  2. npm test -- --watchAll=false
     On failure: fix loop max 3 attempts: fix-agent → re-run
  3. npx playwright test
     On failure: fix loop max 2 attempts: fix-agent [test-code-first] → re-run
  4. Cleanup: kill ports 3000 3001 4000 5173 5174 8080
─────────────────────────────────────────
Playwright: ✅ detected (@playwright/test in devDependencies)
```

---

## Step 0 — Sub-App & Environment Detection

Accept the sub-app path as an argument on invocation, or auto-detect using the steps below.

**CWD-first detection (runs before changed-file scanning):**

Get the current directory name using the detected shell environment and match against known sub-app names:

| CWD name | Type | Node | sub-app path to use |
|---|---|---|---|
| `prac-fe-app-driver` | mobile | 20 | `./` |
| `prac-fe-app-user` | mobile | 20 | `./` |
| `prac-fe-web-manager` | web | 22 | `./` |
| `prac-fe-web-intro` | web | 22 | `./` |
| anything else | — | — | Fall through to changed-file scanning |

**Changed-file scanning (monorepo root fallback):**

Only runs when CWD-first detection did not match.

Accept the sub-app path as an argument on invocation, or auto-detect based on changed files.

| Sub-app | Type | Node | tsc step | E2E step |
|---|---|---|---|---|
| `prac-fe-app-driver` | mobile | 20 | ✅ run | ❌ skip |
| `prac-fe-app-user` | mobile | 20 | ✅ run | ❌ skip |
| `prac-fe-web-manager` | web | 22 | ❌ skip | ✅ (if installed) |
| `prac-fe-web-intro` | web | 22 | ❌ skip | ✅ (if installed) |

**Playwright installation detection**: Run the E2E step only if `@playwright/test` is present in `devDependencies` of `{sub-app}/package.json`. If absent, skip (not an error — just leave a note).

---

## Step 1 — Type Gate (Mobile Apps Only)

Runs only for mobile apps (driver/user). Catches compile errors before `npm test`.

```bash
cd {sub-app path}
npx tsc --noEmit
```

- **Pass**: proceed to Step 2
- **Fail (validate-only)**: output error summary and stop. Do not spawn any agents.
- **Fail (auto-fix)**: collect error log, enter Step 2's fix loop with iteration counter starting at 1

---

## Step 2 — Unit Test Gate

```bash
cd {sub-app path}
npm test -- --watchAll=false
```

### Validate-only mode (default)

If tests fail: output the error summary (max 30 lines) and stop. Do not spawn any agents.

```
[frontend-tdd-runner] ❌ Unit tests failed
[error summary]
→ Fix the errors and re-run.
```

### Auto-fix mode (max 3 attempts)

If tests fail, repeat the fix loop below.

```
iteration = 1  (if already started from tsc failure, carry over that counter)

while iteration <= 3:
  ① delegate to fix-agent
     - pass: full error log + list of failing test files + previous fix history
     - task: analyze the errors AND apply fixes in the same session
     - constraint: only modify files inside the sub-app directory
  ② [mobile] re-run npx tsc --noEmit → npm test
     [web]    re-run npm test
  ③ PASS → break loop, proceed to Step 3
  ④ FAIL → iteration++ → continue
  ⑤ iteration > 3 → output failure report, move to Cleanup
```

Passing previous fix history to the fix-agent prevents circular loops where the same fix is attempted repeatedly.

---

## Step 3 — E2E Gate (Web Only, Max 2 Attempts)

Runs only for web apps where Playwright installation was confirmed in Step 0.

```bash
cd {sub-app path}
npx playwright test
```

### Validate-only mode (default)

If tests fail: output the error summary (max 30 lines) and stop. Do not spawn any agents.

```
[frontend-tdd-runner] ❌ E2E tests failed
[error summary]
→ Fix the errors and re-run.
```

### Auto-fix mode (max 2 attempts)

```
e2e_iteration = 1

while e2e_iteration <= 2:
  ① delegate to fix-agent — apply E2E-specific inspection priority below
     - task: analyze the errors AND apply fixes in the same session
     - constraint: only modify files inside the sub-app directory
  ② re-run npx playwright test
  ③ PASS → break loop
  ④ FAIL → e2e_iteration++
  ⑤ e2e_iteration > 2 → output failure report, move to Cleanup
```

### E2E Failure Fix-Agent Inspection Priority

When E2E fails, instruct the fix-agent to inspect in this order:

1. **Test code itself** — `page.goto()` URLs, `expect()` assertions, selector errors, `waitFor` timeouts
2. **Mocking & intercept setup** — `page.route()`, missing MSW handlers, network stub mismatches
3. **Playwright config** — `baseURL`, `webServer.command`, `timeout` in `playwright.config.ts`
4. **Feature code** — only modify actual component/logic code if none of the above apply

E2E failures are far more often caused by test environment or config issues than actual feature bugs. Touching feature code first creates unnecessary changes and risks breaking unit tests.

---

## Cleanup — Kill Zombie Server Ports

Always runs after Step 2 or Step 3, **regardless of pass or fail**.

**WSL2 / Linux:**
```bash
for port in 3000 3001 4000 5173 5174 8080; do
  fuser -k ${port}/tcp 2>/dev/null || true
done
pkill -f "playwright" 2>/dev/null || true
pkill -f "chromium"   2>/dev/null || true
```

**Windows (PowerShell):**
```powershell
$ports = 3000, 3001, 4000, 5173, 5174, 8080
foreach ($port in $ports) {
  $conn = netstat -ano | Select-String ":$port\s"
  if ($conn) {
    $pid = ($conn[0] -split '\s+')[-1]
    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
  }
}
Get-Process | Where-Object { $_.Name -match "playwright|chromium" } |
  Stop-Process -Force -ErrorAction SilentlyContinue
```

Detect the shell environment and run the appropriate block. Both environments must work without error.

---

## Result Report Format

### Success

```
[frontend-tdd-runner] ✅ All tests passed
Sub-app: prac-fe-web-manager
─────────────────────────────────
Type check : SKIPPED (web)
Unit tests : PASS (23/23)  — 1 fix applied
E2E        : PASS  (5/5)   — no fixes
Cleanup    : done (ports cleared)
─────────────────────────────────
→ Ready to commit
```

### Failure (Loop Exceeded)

```
[frontend-tdd-runner] ❌ Tests failed — commit blocked
Sub-app: prac-fe-web-manager
Failed stage: E2E (after 2 attempts)
─────────────────────────────────
[Last error log summary — max 30 lines]
─────────────────────────────────
Fix history:
  Attempt 1: page.goto() URL mismatch →
             fixed baseURL in playwright.config.ts
  Attempt 2: missing MSW /api/login handler →
             added handler in src/mocks/handlers.ts
─────────────────────────────────
Cleanup: done (ports cleared)
→ Please review manually and re-run.
```
