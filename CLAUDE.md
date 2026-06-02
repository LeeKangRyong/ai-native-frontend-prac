# Project Core Guide

## 1. Structure & Isolation
This is a mono-repository containing 4 completely independent frontend applications.
- **`prac-fe-app-driver`**: Driver Mobile Application
- **`prac-fe-app-user`**: User Mobile Application
- **`prac-fe-web-management`**: Admin Management Web
- **`prac-fe-web-intro`**: Service Web for introducing

### CRITICAL RULE: Absolute Isolation
- **NEVER** modify or reference code outside the directory assigned to your current task.
- Each service must build, deploy, and fail independently. No shared state or cross-imports.

## 2. Reference Guides
For specific instructions, refer to the following files:
- **Environment & Workflow (Git, Branch, Issue):** See `./DEVELOPMENT.md`
- **Sub-project Commands:** See `CLAUDE.md` inside each sub-directory (if available) or check `./DEVELOPMENT.md`.

## 3. Restrictions
- **No Pull Requests:** DO NOT create or push PRs under any circumstances.dh