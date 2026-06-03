---
name: frontend-commit-push
description: >-
  Use this skill whenever the user wants to commit and/or push finished work
  for any of this monorepo's four sub-apps (prac-fe-app-driver,
  prac-fe-app-user, prac-fe-web-manager, prac-fe-web-intro). Follows the
  team's AngularJS-style commit convention (type(scope): 한글 제목 #이슈번호),
  auto-detects scope from changed paths, runs lint then frontend-tdd-runner
  as pre-flight, and pushes directly to the app-specific branch (driver→driver-app, user→user-app, manager→manager-web, intro→intro-web, root→main) — never creates a PR.
  Korean triggers: "커밋하고 푸시해줘", "커밋해줘", "푸시해줘", "변경사항
  커밋해줘", "작업 끝났으니 올려줘", "컨벤션대로 커밋해줘", "작업 완료",
  "이슈 N번 작업 커밋해줘", "feat(user)로 커밋해줘 #12", "올려줘",
  "코드 올려줘". English: "commit my changes", "commit and push", "push
  this". Natural follow-up after frontend-issue-publisher. PRs are
  forbidden — refuse any PR creation requests.
---

# Frontend Commit & Push

Accepts finished changes, runs the CI-equivalent local pre-flight inside the target sub-app, then commits with a convention-compliant message and pushes directly to main. This is the follow-up step to `frontend-issue-publisher`.

## Environment Detection

Detect the shell environment once at invocation start and use it throughout all steps:

| Test | WSL / bash | Windows PowerShell / CMD |
|---|---|---|
| Detect shell | `uname -s` → `Linux` | `uname` not found, or `$IsWindows` is `$true` |
| Current dir name | `basename "$(pwd)"` | `Split-Path -Leaf (Get-Location)` |
| Full path | `pwd` | `(Get-Location).Path` |

---

## Pre-condition — Re-read conventions every run

Read `DEVELOPMENT.md` on each invocation to confirm that the type/scope whitelist and message format have not changed. The content below reflects the current baseline; the file takes precedence.

- **Commit format**: `[type]([scope]): [Korean title ≤50 chars] #[issue number]`
- **Allowed types**: `feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`
- **Allowed scopes**: `driver, user, manager, intro, root`

---

## Dry-Run Mode

If the utterance contains `dry-run`, `확인만 해줘`, `실행 말고 보여줘`, or `미리 보기만`, operate in dry-run mode.

- **Steps 1–5 run as normal** (scope detection, branch check, pre-flight, message validation all execute for real).
- **Stop at Step 6**: do not execute `git commit` or `git push`. Instead, output the commands that would run and the final commit message.
- Output format:
  ```
  [DRY-RUN] Not actually executing
  Commit message: feat(user): 로그인 화면 구현 #12
  Push command: git push origin user-app
  ```

---

## Step 1 — Collect Change Scope

Combine `git status --porcelain`, `git diff --name-only` (staged + unstaged), and `git ls-files --others --exclude-standard` (new untracked) to get the full list of changed files.

If there are no changes, report immediately and stop.

---

## Step 2 — Auto-Detect Scope & Isolation Check

Map each file's top-level directory segment to a scope:

| Directory | Scope |
|---|---|
| `prac-fe-app-driver/` | `driver` |
| `prac-fe-app-user/` | `user` |
| `prac-fe-web-manager/` | `manager` |
| `prac-fe-web-intro/` | `intro` |

**CWD-first detection (runs before prefix matching):**

Get the current directory name using the detected shell environment and match against known sub-app names:

| CWD name | Scope | Action |
|---|---|---|
| `prac-fe-app-driver` | `driver` | Scope confirmed — skip prefix matching |
| `prac-fe-app-user` | `user` | Scope confirmed — skip prefix matching |
| `prac-fe-web-manager` | `manager` | Scope confirmed — skip prefix matching |
| `prac-fe-web-intro` | `intro` | Scope confirmed — skip prefix matching |
| anything else | — | Fall through to prefix matching below |

**Prefix matching (monorepo root fallback):**

Only runs when CWD-first detection did not match (i.e., Claude is running from the monorepo root).

**Detection rules:**

- **Single sub-app** → scope confirmed, continue.
- **Changes span 2+ sub-apps** → monorepo isolation violation. One commit must cover only one sub-app. Ask the user which sub-app to commit now and guide them to split the rest into a separate commit.
- **Only root files changed** (e.g., `.github/`, root `*.md`, `.claude/`, `.gitattributes`) → scope auto-set to `root`. Do not ask the user.
- If the user's utterance names a scope and it differs from the auto-detected scope, warn and ask for confirmation. Honor user intent but never proceed with the wrong scope.

---

## Step 3 — Local Pre-Flight Gate

Run the following inside the detected sub-app directory. Stop immediately if any step fails.

**Working directory**: If CWD was already the target sub-app (confirmed via CWD-first detection in Step 2), run commands directly without `cd`. Otherwise `cd {sub-app-dir}` first.

| Sub-app | Node | Pre-flight commands |
|---|---|---|
| `prac-fe-app-driver` (driver) | 20 | `npm ci` → `npm run lint` → `frontend-tdd-runner` |
| `prac-fe-app-user` (user) | 20 | `npm ci` → `npm run lint` → `frontend-tdd-runner` |
| `prac-fe-web-manager` (manager) | 22 | `npm ci` → `npm run lint` → `frontend-tdd-runner` |
| `prac-fe-web-intro` (intro) | 22 | `npm ci` → `npm run lint` → `frontend-tdd-runner` |

`frontend-tdd-runner` handles tsc (mobile only) → unit tests → E2E (web, if Playwright is installed) in sequence, with an auto-fix loop (unit max 3 attempts, E2E max 2 attempts), and cleans up zombie server ports on completion.

**Failure handling:**
- `npm run lint` fails → summarize the lint output and stop. Do not auto-fix lint errors.
- `frontend-tdd-runner` fails (loop exceeded) → pass the tdd-runner's fix history and last error log directly to the user and stop.
- Never bypass using `--no-verify` or equivalent.
- If the local Node version differs from the CI baseline (20/22), emit a one-line warning (do not block).
- If a script (e.g., `npm run lint`) is missing from `package.json`, report the fact and ask the user whether to continue.

---

## Step 4 — Branch & Remote State Check

Before assembling the commit message, verify git state and prepare the target branch.

1. Run `git status --porcelain` to check for merge conflict markers (`UU`, `AA`, `DD`). If found, stop immediately.
2. Verify no uncommitted changes exist outside the target sub-app directory. If changes span multiple sub-apps, warn the user and stop.

---

## Step 5 — Assemble & Validate Commit Message

Build the message as: `[type]([scope]): [Korean title] #[issue number]`

**Validation rules:**

- **type**: must be from the allowed list (`feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`). Reject and request re-input if not.
- **scope**: must match the scope confirmed in Step 2.
- **Korean title**: ≤50 characters. If over, shorten and confirm with the user.
- **Issue number**: `#<number>` required for sub-app scopes (`driver`, `user`, `manager`, `intro`). Try to extract from the utterance, branch name, or recent issues. If not found, **do not guess** — ask the user. **Optional for `root` scope** — omit if not provided.

---

## Step 6 — Preview → Confirm → Checkout → Commit → Push → Return

Show the user the commit message and push command, and wait for explicit approval.

After approval, execute the following sequence without interruption:

1. **Pre-checkout safety check**: Run `git status --porcelain` and confirm no uncommitted changes exist outside the target sub-app directory. If any exist, warn the user and stop.
2. `git checkout <target-branch>` — switch to the target branch before committing. If the local branch does not exist, run `git checkout -b <target-branch> origin/<target-branch>` to create a local tracking branch.
3. `git add` — restrict scope to the target sub-app directory only.
4. `git commit -m "..."` — commit with the confirmed message.
5. `git push origin <target-branch>` — push only this branch to origin:

   | Scope   | Target Branch |
   |---------|---------------|
   | driver  | driver-app    |
   | user    | user-app      |
   | manager | manager-web   |
   | intro   | intro-web     |
   | root    | main          |

6. `git checkout main` — return to main branch after push. **Skip this step if scope is `root`** (already on main).

On success, report the commit hash to the user.

**Never create a PR.** If the user requests a PR creation or merge, refuse and explain why (project rule: PRs are forbidden).

---

## Examples

**Example 1 — Normal flow (mobile, user)**

```
이슈 12번 user 앱 로그인 화면 작업 끝났어. 커밋하고 푸시해줘.
```

Flow: only `prac-fe-app-user/**` changed → scope=`user` → lint passes → `frontend-tdd-runner` passes (tsc + unit tests) → message preview `feat(user): 로그인 화면 구현 #12` → approved → push to user-app.

**Example 2 — Pre-flight failure (web, manager)**

```
manager 변경 커밋해줘 #7
```

Flow: scope=`manager` → web so tsc skipped → `npm run lint` fails → commit stopped, ESLint output summarized. Ends with "please fix lint errors and re-run".

**Example 3 — Missing issue number**

```
지금 변경사항 커밋해줘
```

Flow: issue number not found in utterance or branch name → do not guess → ask user for issue number. Do not commit until confirmed.
