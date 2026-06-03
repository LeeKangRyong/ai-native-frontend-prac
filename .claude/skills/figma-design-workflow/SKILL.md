---
name: figma-design-workflow
description: >-
  Orchestrates the full design phase for React Native (Expo) mobile apps
  (prac-fe-app-driver, prac-fe-app-user) in this monorepo. Reads .ai/API.md,
  .ai/CONVENTIONS.md, and .ai/DESIGN.md to synthesize a structured design
  proposal, presents it for human review, then generates Figma screens via
  Figma MCP after approval — always gating Figma calls behind explicit user
  confirmation. Use this skill whenever the user wants to start the design
  phase, plan UI before writing code, or draw screens in Figma for a mobile
  app. Trigger especially for Korean phrases like "디자인 시작해줘", "figma 그려줘",
  "화면 디자인해줘", "디자인부터 시작해줘", "figma에 그려줘", or English phrases
  like "design first", "start design", "draw in figma", "generate figma
  screens". Always use this skill before any code is written for a new screen
  or feature in the driver or user mobile apps.
---

# figma-design-workflow

Bridges the app's design spec files (.ai/) to Figma screens with a human approval gate in between. The key principle: read what was specified, synthesize a coherent proposal, get the human's sign-off on structure, *then* draw in Figma. This order matters — Figma generation is not free to revise, so confirming the structure first prevents wasted work.

## Frame Standard (Applies to All Figma Screens)

All screens in this workflow use the **390×844 frame (iPhone 14 standard)**. This is the team's agreed design baseline.

- **Frame size**: 390 × 844 px
- **Safe Area (Figma overlay)**: top 59 px / bottom 34 px
  - The Safe Area component (key: `00bfa96bea64def82819c61edd40191f09294123`) must be overlaid on every screen after it is drawn
  - Content should be designed to stay within the safe content zone: y=59 to y=810
- **Runtime Safe Area in code**: handled by `react-native-safe-area-context` (not hardcoded) — see `IMPLEMENTATION_SLOT.md`

This matters because the previous standard (375×667) is outdated. Using 390×844 ensures designs align with modern iPhone dimensions and match what the code harness expects.

## Step 0 — Detect Target App

Determine whether the task is for `prac-fe-app-driver` or `prac-fe-app-user`.

- Look at recently modified files or explicit mention in the user's request
- If genuinely ambiguous, ask: "driver 앱과 user 앱 중 어느 앱의 디자인을 시작할까요?"
- This skill is for mobile apps only — never access `prac-fe-web-management` or `prac-fe-web-intro`

## Step 1 — Read Design Spec Files

Read all three in parallel from the detected app's `.ai/` directory:

| File | Purpose |
|---|---|
| `.ai/API.md` | Data structures, endpoints → what UI needs to display |
| `.ai/CONVENTIONS.md` | Naming rules, folder structure, component patterns |
| `.ai/DESIGN.md` | Screen list, design tokens, component library |

If a file is empty or contains only template comments, note it briefly and continue — partial information still produces a useful proposal, and the user chose to leave it empty.

## Step 2 — Synthesize Design Proposal

Output a structured proposal **before touching Figma**. This is cheap to revise; Figma is not.

```
## Design Proposal — [App Name]

### Frame Standard
모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px

### Design Tokens
[Colors, typography, spacing from DESIGN.md. If empty, show "미정 (DESIGN.md 작성 필요)"]

### Screen Inventory
[Each screen: name | route | key components | states]

### Component Hierarchy
[Shared components that appear across 2+ screens]

### API → UI Mapping
[How each endpoint maps to a screen state or component prop]
```

Close with: **"이 구조로 Figma에 그려드릴까요? 수정이 필요하면 말씀해주세요."**

## Step 3 — Wait for Approval

Do not call Figma until the user explicitly confirms. Phrases that mean "yes, proceed":
- "이 구조로 그려줘" / "그대로 그려줘" / "ok" / "진행해줘" / "좋아" / "맞아"

If the user requests changes ("홈 화면에 검색 바 추가해줘"), update the proposal in-place and show it again. Repeat until an approval phrase is received.

## Step 4 — Generate Figma Screens

After approval:

1. Load `/figma-generate-design` skill — mandatory prerequisite before any Figma MCP call
2. Read `{app}/figma.config.json` for the `figmaFile` URL and target node-id:
   - `prac-fe-app-driver` → node-id `8-2`
   - `prac-fe-app-user` → node-id `0-1`
3. For **each screen** in the approved Screen Inventory:
   a. Create a frame of exactly **390 × 844 px** — never use 375×667 or any other size
   b. Design content within the safe content zone: top padding 59px, bottom padding 34px
   c. After the screen content is complete, overlay the Safe Area component (key: `00bfa96bea64def82819c61edd40191f09294123`) at x=0, y=0 on the frame — this shows designers the restricted zones
4. Add screens as children of the target node — do not create a new Figma file
5. Position screens on the canvas with 100px spacing between them (e.g., x=0, x=490, x=980…)

### Why 390×844 matters here

The Safe Area component and IMPLEMENTATION_SLOT.md are both built around this baseline. If a screen is drawn at a different size, the Safe Area overlay won't align, and the code harness (which expects 390×844 ratios) will produce mismatched layouts.

## Step 5 — Close with Approval Gate

After generation:

```
Figma 링크: [url]

검토 후:
  수정이 필요하면 → "이 화면 수정해줘"
  승인하면        → "구현 시작해줘" 또는 "코드 작성해줘"
```

Stop here. Do not begin code generation. Phase C starts only on explicit user approval.

---

## Dry-Run Mode

Triggered by: `"확인만 해줘"`, `"dry-run"`, `"미리 보기만"`

Run Steps 0–2 only. Output `[DRY-RUN]` at the top. Do not call Figma.

```
[DRY-RUN] Figma 호출 없이 설계 제안만 출력합니다.

## Design Proposal — [App Name]

### Frame Standard
모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px

...
```

---

## Isolation Rule

Only access files inside the target app directory (`prac-fe-app-driver/` or `prac-fe-app-user/`). Never read from `prac-fe-web-management/` or `prac-fe-web-intro/`.
