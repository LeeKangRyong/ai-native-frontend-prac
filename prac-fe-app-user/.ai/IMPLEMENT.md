# IMPLEMENT — User App

## Entry Conditions

- `figma-design-workflow` skill completed + Figma approved
- User implementation start signal ("구현 시작해줘" / "harness 돌려줘" / "implement" / "start dev")

## Input Context

| File | Role |
|---|---|
| `.ai/DESIGN.md` | Screen list + component spec → implementation scope |
| `.ai/CONVENTIONS.md` | Folder structure + naming rules → code conventions |
| `.ai/API.md` | Endpoints + types → TypeScript definition base |

## Completion Criteria

- [ ] All Screens from `.ai/DESIGN.md` implemented (`src/screens/`)
- [ ] Folder structure / naming rules from `.ai/CONVENTIONS.md` followed
- [ ] `.stories.tsx` exists for each component
- [ ] `SafeAreaProvider` exists at app root
- [ ] `useSafeAreaInsets()` or `SafeAreaView` used in each Screen
- [ ] No hardcoded padding top/bottom (Safe Area handled at runtime)
- [ ] No imports from other sub-app directories
- [ ] `npx tsc --noEmit` passes
- [ ] `npm test -- --watchAll=false` passes

## Safe Area Spec

- Figma frame: 390×844 (iPhone 14)
- Safe Area: top 59px / bottom 34px (Figma reference; runtime handled by react-native-safe-area-context)
- Required package: `react-native-safe-area-context`

## Skill Chain

```
[frontend-implement-harness]
  Stage 5 → frontend-tdd-runner (validate-only)
  Stage 6 → frontend-commit-push
```
