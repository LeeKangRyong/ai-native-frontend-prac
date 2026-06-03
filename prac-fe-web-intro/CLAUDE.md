# Intro Web Guide (prac-fe-web-intro)

## Build & Dev Commands
- **Install Dependencies:** `npm install`
- **Run Development Server:** `npm run dev`
- **Build Project:** `npm run build`
- **Lint / Style Check:** `npm run lint`
- **Test:** `npm test`

## Tech Stack & Rules
- Language: TypeScript
- Framework: Next.js
- Rule: Do not import any files from outside this `prac-fe-web-intro` directory.

## Execution Context

This Claude instance runs with `prac-fe-web-intro/` as the working directory (tmux 2×2 layout).
- All relative paths use `./` as the base (this directory)
- Monorepo root is one level up: `../`
- Git scope for this pane is always `intro` — no scope detection needed
- Skills are loaded from `../.claude/skills/` and work correctly from this CWD
- Shell environment: WSL/bash (tmux) or Windows PowerShell/CMD — skills handle both

## Skill Scope

| Skill | Trigger example |
|---|---|
| `frontend-issue-publisher` | "이슈 만들어줘" |
| `frontend-tdd-runner` | "테스트 돌려줘" / "테스트 고쳐줘" |
| `frontend-commit-push` | "커밋하고 푸시해줘" |
| `figma-design-workflow` | "디자인 시작해줘" |

Git commit scope fixed to: `intro`