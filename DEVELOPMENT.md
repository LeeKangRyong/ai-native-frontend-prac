# Development Environment & Workflow Guide

## 1. Environment (WSL2 + tmux)
- This project runs on a WSL2 and tmux-based environment.
- Initialized and managed via `./start-tmux.sh`.
- *Note for Claude:* Always ensure you are executing commands in the correct directory context corresponding to the active tmux pane/window.

### Dual-Environment Notice

Claude may be invoked from two distinct environments. Skills must handle both without error:

| Environment | Shell | How Claude is launched |
|---|---|---|
| **WSL / tmux** | bash | `start-tmux.sh` → 4 panes, each `cd`'d into a sub-app, runs `claude --dangerously-skip-permissions` |
| **Windows** | PowerShell / CMD | Claude Code desktop app or direct terminal session from the monorepo root |

**tmux pane → sub-app mapping:**

| Pane | CWD | Git scope |
|---|---|---|
| Top-left | `prac-fe-app-user/` | `user` |
| Top-right | `prac-fe-app-driver/` | `driver` |
| Bottom-left | `prac-fe-web-manager/` | `manager` |
| Bottom-right | `prac-fe-web-intro/` | `intro` |

When running from a sub-app CWD, skills detect the scope from the directory name and use `./` for all paths. Monorepo-root invocation falls back to prefix-based detection.

## 2. Git Workflow

### Branch Naming Convention
Before starting any task, create a dedicated branch:
- Format: `[type]([scope])/#[issue_number]-[description]`
- Example: `feat(user)/#3-ios`

### Commit Message Convention
Follow AngularJS Convention. The body/subject must be in **Korean (한글) and under 50 characters**.
- **Allowed Scopes:** `driver`, `user`, `manager`, `intro`, `root`
- **Format:** `[type]([scope]): [Subject in Korean] #[issue_number]`
- **Examples:**
  - `feat(driver): 실시간 경로 추적 오류 해결 #3`
  - `fix(manager): 로그인 세션 만료 얼럿 추가 #12`
  - `chore(root): 루트 커밋 컨벤션 정의`

#### `root` scope 규칙
- **적용 대상:** `.claude/`, `CLAUDE.md`, `DEVELOPMENT.md`, `README.md`, `.github/`, `.gitattributes`, `start-tmux.sh` 등 서브앱 디렉토리 밖의 모든 파일
- **issue# 선택 사항:** 유지보수·설정 변경은 트래킹 이슈 없이 진행하는 경우가 많으므로 생략 가능

## 3. Issue Generation
When instructed to create an issue, use the template: `./.github/ISSUE_TEMPLATE/task_ex.md`.
- Read the markdown template and generate the issue content precisely based on the prompt.