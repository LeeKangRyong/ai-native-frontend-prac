---
name: frontend-implement-harness
description: Runs a 6-stage automated implementation pipeline for this monorepo's frontend apps. Use this skill whenever the user says "구현 시작해줘", "harness 돌려줘", "implement", "개발 시작해줘", "start dev", or any phrase indicating they want to begin coding a feature end-to-end. Also trigger for "dry-run", "확인만", or "계획만" to preview the pipeline without writing code. The skill reads .ai/IMPLEMENT.md, orchestrates Planner → Coder → Static Critic → Code Reviewer → Test Runner → Verifier sub-agents, and commits the result. Always use this skill when implementation work begins for any of the 4 monorepo apps (prac-fe-app-driver, prac-fe-app-user, prac-fe-web-manager, prac-fe-web-intro).
triggers:
  - "구현 시작해줘"
  - "harness 돌려줘"
  - "implement"
  - "개발 시작해줘"
  - "start dev"
  - "dry-run"
  - "확인만"
  - "계획만"
---

# Frontend Implement Harness

An automated 6-stage pipeline that takes a completed `.ai/IMPLEMENT.md` and produces committed, tested code. Each stage delegates to a specialized sub-agent — the orchestrator holds only file paths, keeping context lean across the long pipeline.

## Pipeline Overview

```
Stage 0: Guard        — verify inputs, detect app type, initialize state
Stage 1: Planning     — Planner ↔ Plan Critic loop (max 3), user approval gate
Stage 2: Coding       — Executor per task step [compact checkpoint #1]
Stage 3: Static Gate  — Critic ↔ Analyst ↔ Fix Executor loop (max 3)
Stage 4: Code Review  — Reviewer ↔ Analyst ↔ Fix Executor → re-enter Stage 3 (max 3)
                        [compact checkpoint #2]
Stage 5: Testing      — frontend-tdd-runner ↔ Debugger ↔ Fix Executor (max 3)
Stage 6: Completion   — Verifier → frontend-commit-push
```

---

## Stage 0: Guard

Detect app type from CWD and verify required input files before spawning any agents.

### App Type Detection

| CWD pattern | app_type |
|---|---|
| `*app-driver*` or `*app-user*` | `mobile` |
| `*web-manager*` or `*web-intro*` | `web` |

If CWD matches none of these, abort:
```
ERROR: Cannot detect app type from CWD: <cwd>
Expected one of: prac-fe-app-driver, prac-fe-app-user, prac-fe-web-manager, prac-fe-web-intro
```

### File Checks

1. `.ai/IMPLEMENT.md` — **required**. If missing, abort immediately:
   ```
   ERROR: .ai/IMPLEMENT.md not found.
   Run the figma-design-workflow skill first, then populate .ai/IMPLEMENT.md.
   Aborting — Stage 1 and beyond will not execute.
   ```

2. `.ai/DESIGN.md` — warn if empty but continue.
3. `.ai/CONVENTIONS.md` — warn if empty but continue.

### HarnessContext Initialization

Write initial state to `.omc/state/harness-{session_id}.json`:
```json
{
  "session_id": "<session id>",
  "app_type": "mobile | web",
  "cwd": "<absolute path>",
  "stage": 0,
  "stage_1_iterations": 0,
  "stage_3_iterations": 0,
  "stage_4_iterations": 0,
  "stage_5_iterations": 0,
  "artifacts": {}
}
```

Create `.omc/state/harness-artifacts/` for agent output files.

### Dry-Run Mode

If the trigger contains "dry-run", "확인만", or "계획만":
1. Print: detected app_type, CWD, file check results
2. Print: full Stage 0–6 pipeline with planned agents for this app_type
3. **Stop here. Do not modify any source files.**

---

## Stage 1: Planning Loop (max 3 iterations)

Goal: produce a Task Breakdown the user approves before any code is written.

### 1a. Planner

Spawn `oh-my-claudecode:planner` (opus) with `.ai/IMPLEMENT.md`, `.ai/DESIGN.md`, `.ai/CONVENTIONS.md`, and `.ai/API.md` (if exists).

Task: produce a numbered Task Breakdown JSON:
```json
{
  "tasks": [
    {"id": 1, "title": "...", "files": ["src/types/..."], "depends_on": []},
    ...
  ]
}
```

Save raw output → `.omc/state/harness-artifacts/stage1-planner-iter{N}.txt`.

### 1b. Plan Critic

Spawn `oh-my-claudecode:critic` (opus) with Task Breakdown + `../DEVELOPMENT.md`.

Task: verify breakdown covers all IMPLEMENT.md completion criteria, respects CONVENTIONS.md, no cross-app imports.
Returns `APPROVED` or `REJECTED: <reason>`.

Save raw output → `.omc/state/harness-artifacts/stage1-critic-iter{N}.txt`.

### Loop Logic

- `APPROVED` → show Task Breakdown to user, **ask for approval** before Stage 2.
- `REJECTED` → pass critic feedback back to Planner, increment `stage_1_iterations`.
- `stage_1_iterations >= 3` → abort:
  ```
  ABORT: Stage 1 failed after 3 iterations.
  Last critic feedback: <feedback>
  Review .ai/IMPLEMENT.md and retry.
  ```

**User approval gate**: Do not proceed to Stage 2 without explicit user confirmation.

---

## Stage 2: Coding Phase

Spawn `oh-my-claudecode:executor` (sonnet) **once per task** in the approved Task Breakdown, sequentially.

Each executor call receives the task spec + relevant IMPLEMENT.md sections + CONVENTIONS.md.

After all tasks:
```
[compact checkpoint #1]
Stage 2 complete — <N> tasks implemented. Compacting before static review.
```
Invoke `/compact` to reduce orchestrator context before Stage 3.

---

## Stage 3: Static Gate (max 3 iterations)

Goal: catch cross-app imports, Safe Area violations (mobile), and convention drift.

### 3a. Critic (sonnet)

Spawn `oh-my-claudecode:critic` with all modified files + IMPLEMENT.md criteria + CONVENTIONS.md.

Checks:
- Any `import` referencing a path outside the current sub-app directory
- **mobile only**: hardcoded numeric padding top/bottom without `useSafeAreaInsets`
- Naming convention violations from CONVENTIONS.md

Returns `PASS` or `FAIL: <violation list>`.

### 3b. On FAIL

1. Spawn `oh-my-claudecode:analyst` (sonnet) → Fix Directive saved to `harness-artifacts/stage3-fix-directive-iter{N}.txt`
2. Spawn `oh-my-claudecode:executor` (sonnet) → apply Fix Directive

### Loop Logic

- `PASS` → Stage 4
- `FAIL` → fix + increment `stage_3_iterations`
- `stage_3_iterations >= 3` → abort with final violation list

---

## Stage 4: Code Review Gate (max 3 iterations)

Goal: production-quality code — performance, readability, extensibility, error handling.

### 4a. Reviewer (sonnet)

Spawn `oh-my-claudecode:code-reviewer` with all modified source files.
Returns `PASS` or `FAIL: <review items>`.

### 4b. On FAIL

1. Spawn `oh-my-claudecode:analyst` (sonnet) → Task List from review items
2. Spawn `oh-my-claudecode:executor` (sonnet) → apply fixes

### Loop Logic

- `PASS` → **re-enter Stage 3** (static re-validation after code changes)
  - Stage 3 PASS → Stage 5
- `FAIL` → fix + increment `stage_4_iterations`
- `stage_4_iterations >= 3` → abort with final review items

After Stage 4 PASS + Stage 3 re-validation PASS:
```
[compact checkpoint #2]
Stage 4 complete — code reviewed and statically validated. Compacting before tests.
```
Invoke `/compact`.

---

## Stage 5: Testing Loop (max 3 iterations)

Goal: all tests green before commit.

### 5a. Test Runner

Invoke `frontend-tdd-runner` skill in **validate-only** mode (no auto-fix):
- **mobile**: `npx tsc --noEmit` + `npm test -- --watchAll=false`
- **web**: `npm run lint` + `npm test` + Playwright E2E (if configured)

Returns `ALL_PASS` or `FAIL: <error log>`.

Save error log → `harness-artifacts/stage5-test-fail-iter{N}.txt`.

### 5b. On FAIL

1. Spawn `oh-my-claudecode:debugger` (sonnet) → root cause + Fix Directive
2. Spawn `oh-my-claudecode:executor` (sonnet) → apply Fix Directive

### Loop Logic

- `ALL_PASS` → Stage 6
- `FAIL` → fix + increment `stage_5_iterations`
- `stage_5_iterations >= 3` → abort:
  ```
  ABORT: Stage 5 failed after 3 attempts.
  Last error log: <path>
  Manual intervention required.
  ```

---

## Stage 6: Completion

### 6a. Verifier (opus)

Spawn `oh-my-claudecode:verifier` with `.ai/IMPLEMENT.md` (completion criteria checklist) + list of modified files + Stage 5 test results.

Verifier checks every `## Completion Criteria` checkbox.
- `VERIFIED` → proceed to commit
- `INCOMPLETE: <missing items>` → report to user and halt. Do not commit.

### 6b. Commit & Push

Invoke `frontend-commit-push` skill with modified files + Stage 6 verification summary.
`frontend-commit-push` handles git add, commit (scope + issue number), and push.

### Final Report

```
Stage 6 complete.
Commit: <hash>
Files changed: <N>
All IMPLEMENT.md completion criteria verified. ✓
```

---

## Context Management

- **HarnessContext**: `.omc/state/harness-{session_id}.json` — update at every stage boundary
- **Agent outputs**: save raw text to `.omc/state/harness-artifacts/` — orchestrator holds paths only, never raw content
- **Compact checkpoints**: invoke `/compact` after Stage 2 and after Stage 4+Stage 3 re-validation

## Error Handling

On any unrecoverable abort:
1. Update HarnessContext: `status: "aborted"`, `abort_stage: N`, `abort_reason: "..."`
2. Print a clear human-readable summary: what failed, which stage, how to resume
3. Never silently swallow errors

## Agent Roster

| Stage | Role | Agent | Model |
|---|---|---|---|
| 1 | Planner | `oh-my-claudecode:planner` | opus |
| 1 | Plan Critic | `oh-my-claudecode:critic` | opus |
| 2 | Coder | `oh-my-claudecode:executor` | sonnet |
| 3 | Static Critic | `oh-my-claudecode:critic` | sonnet |
| 3 | Fix Analyst | `oh-my-claudecode:analyst` | sonnet |
| 3 | Fix Coder | `oh-my-claudecode:executor` | sonnet |
| 4 | Reviewer | `oh-my-claudecode:code-reviewer` | sonnet |
| 4 | Review Analyst | `oh-my-claudecode:analyst` | sonnet |
| 4 | Review Fix Coder | `oh-my-claudecode:executor` | sonnet |
| 5 | Debugger | `oh-my-claudecode:debugger` | sonnet |
| 5 | Test Fix Coder | `oh-my-claudecode:executor` | sonnet |
| 6 | Verifier | `oh-my-claudecode:verifier` | opus |
