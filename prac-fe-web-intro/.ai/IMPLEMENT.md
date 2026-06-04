# IMPLEMENT — Intro Web

## Entry Conditions

- `figma-design-workflow` skill completed + Figma approved
- User implementation start signal ("구현 시작해줘" / "harness 돌려줘" / "implement" / "start dev")

## Input Context

| File | Role |
|---|---|
| `.ai/DESIGN.md` | Page list + component spec → implementation scope |
| `.ai/CONVENTIONS.md` | Folder structure + naming rules → code conventions |
| `.ai/API.md` | Endpoints + types → TypeScript definition base |

## Completion Criteria

- [ ] All Pages from `.ai/DESIGN.md` implemented
- [ ] Folder structure / naming rules from `.ai/CONVENTIONS.md` followed
- [ ] `.stories.tsx` exists for each component
- [ ] No imports from other sub-app directories
- [ ] `npm run lint` passes
- [ ] `npm test` passes
- [ ] Playwright E2E passes (if installed)

## Skill Chain

```
[frontend-implement-harness]
  Stage 5 → frontend-tdd-runner (validate-only)
  Stage 6 → frontend-commit-push
```
