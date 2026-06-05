---
name: figma-design-workflow
description: >-
  MANDATORY skill — invoke INSTEAD of writing code whenever any UI screen,
  page, or component design is requested for this monorepo's 4 apps.
  Do NOT use the frontend-design skill for this project.
  Reads .ai/ spec files, synthesizes a design proposal, then draws in Figma after approval.
  Works even when DESIGN.md is empty — uses style direction from the user's request instead.
  Trigger for Korean: "디자인해줘", "디자인해달라", "디자인해주세요",
  "UI 그려줘", "화면 그려줘", "디자인 해줘", "디자인 작업해줘", "figma 시작해줘",
  "디자인 시작해줘", "figma 그려줘", "화면 디자인해줘", "디자인부터 시작해줘",
  "figma에 그려줘", "웹 디자인해줘", "[스타일]로 디자인해줘",
  "[회사명] 디자인으로 해줘", "[화면명] 화면 디자인해줘",
  "관리자 화면 그려줘", "인트로 페이지 디자인해줘", "관리자 웹 디자인해줘".
  Trigger for English: "design first", "start design", "draw in figma",
  "generate figma screens", "design the web app", "design the admin panel",
  "design the landing page", "design the intro page", "design this", "design it",
  "design with [style] style", "use [company] design".
  Always use this skill before any code is written for a new screen or feature
  in any of the four apps.
---

# figma-design-workflow

Bridges the app's design spec files (.ai/) to Figma screens with a human approval gate in between. The key principle: read what was specified, synthesize a coherent proposal, get the human's sign-off on structure, *then* draw in Figma. This order matters — Figma generation is not free to revise, so confirming the structure first prevents wasted work.

> **DESIGN-ONLY BOUNDARY**
> This skill produces **Figma screens only**. It MUST NOT generate, scaffold, or modify any source code file at any point — regardless of whether code already exists in the app. Code generation begins only after the user explicitly says "구현 시작해줘" or "코드 작성해줘" in a separate conversation turn.

## Platform Frame Standards

Frame sizes and constraints differ between mobile and web. The skill must use the correct standard for the detected platform.

### Mobile (prac-fe-app-driver, prac-fe-app-user)

- **Frame size**: 390 × 844 px (iPhone 14 standard)
- **Safe Area overlay**: top 59 px / bottom 34 px
  - The Safe Area component (key: `00bfa96bea64def82819c61edd40191f09294123`) must be overlaid on every screen after it is drawn
  - Content should be designed to stay within the safe content zone: y=59 to y=810
- **Runtime Safe Area in code**: handled by `react-native-safe-area-context` — see `IMPLEMENTATION_SLOT.md`

The 390×844 baseline ensures designs align with modern iPhone dimensions and match what the code harness expects. The previous standard (375×667) is outdated — never use it.

### Web (prac-fe-web-manager, prac-fe-web-intro)

- **Frame size**: 1440 × 900 px (standard desktop viewport)
- **No Safe Area overlay** — browsers don't have notch/home indicator constraints
- **Responsive note**: If `DESIGN.md` specifies breakpoints, document them in the proposal, but the 1440×900 desktop frame is the primary Figma deliverable. Tablet and mobile breakpoints are noted in the proposal text, not drawn as separate frames unless explicitly requested.

## Step 0 — Detect Target App

Determine which of the 4 apps the task is for, and classify its platform.

| App | Platform | Stack | Figma node-id |
|---|---|---|---|
| prac-fe-app-driver | mobile | React Native (Expo) | 8-2 |
| prac-fe-app-user | mobile | React Native (Expo) | 0-1 |
| prac-fe-web-manager | web | React + Vite SPA | 8-3 |
| prac-fe-web-intro | web | Next.js (App Router) | 8-4 |

Detection priority (highest to lowest):
1. **CWD first**: If the working context is inside one of the 4 app directories
   (`prac-fe-app-driver/`, `prac-fe-app-user/`, `prac-fe-web-manager/`, `prac-fe-web-intro/`),
   use that app. This overrides all other signals.
2. **Explicit mention**: If the user's request names an app directly, use that.
3. **Recently modified files**: If CWD is the repo root and no app is named,
   look at which app directory had the most recent file changes.
4. **Ambiguous fallback**: If still unclear, ask:
   "driver, user, web-manager, web-intro 중 어느 앱의 디자인을 시작할까요?"
- Set `platform = "mobile"` for driver/user, `platform = "web"` for manager/intro — this drives template branching in Steps 2 and 4

## Step 1 — Read Design Spec Files

Attempt to read all available files in parallel from the detected app's `.ai/` directory:

| File | Status | Purpose |
|---|---|---|
| `.ai/API.md` | **Optional** | Data structures, endpoints → what UI needs to display |
| `.ai/CONVENTIONS.md` | Preferred | Naming rules, folder structure, component patterns |
| `.ai/DESIGN.md` | Preferred | Screen/page list, design tokens, component library |

**IMPORTANT**: Read ONLY files under the `.ai/` directory. Do NOT read `src/`, `app/`, `components/`, or any other source code files — this skill operates from specs and user intent alone, not from existing code. **When no code exists yet**: this is the expected state. Missing `.ai/` files or empty spec files are handled by inference (Step 2). Never fail or pause because source code doesn't exist.

**API.md is optional.** If the file does not exist or is empty, do not treat it as an error — skip it silently and set `has_api_spec = false`. When it is missing, infer data display needs from:
- Screen/component names in `DESIGN.md` (e.g., "OrderListScreen" implies a list of orders with status fields)
- Component and naming patterns in `CONVENTIONS.md`
- Any data context the user explicitly mentioned in their request

If `CONVENTIONS.md` or `DESIGN.md` is empty or contains only template comments, note it briefly and continue — partial information still produces a useful proposal.

**When DESIGN.md is empty AND the user specifies a style reference** (e.g., "TOSS 디자인으로 해줘", "카카오 스타일로", "Material Design으로"):
- Do NOT abort or skip to implementation
- Treat the named brand/style as the design token source
- In the proposal, document inferred design tokens based on that brand's known design system (colors, typography, spacing, component patterns)
- Mark these tokens as `[추론됨 — {brand} 디자인 시스템 기반]` so the user knows they are inferred, not from DESIGN.md
- Proceed normally through Steps 2–5

## Step 2 — Synthesize Design Proposal

Output a structured proposal **before touching Figma**. The template branches by platform. This is cheap to revise; Figma is not.

### Mobile proposal template

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

### Data Requirements
[has_api_spec=true → "API → UI Mapping: 각 엔드포인트가 어떤 화면 상태/prop에 매핑되는지"]
[has_api_spec=false → "API.md 미제공 — 화면 이름/컴포넌트 기반 추론된 데이터 필드:
  예) HomeScreen: 배차 상태(status), 기사 이름(driverName), ...
  실제 API 연동 시 수정이 필요할 수 있습니다."]
```

### Web proposal template

```
## Design Proposal — [App Name]

### Frame Standard
데스크탑 프레임: 1440×900 | Safe Area 없음 (브라우저 환경)
[web-intro only: 반응형 브레이크포인트가 DESIGN.md에 지정된 경우 나열]

### Design Tokens
[Colors, typography, spacing from DESIGN.md. If empty, show "미정 (DESIGN.md 작성 필요)"]

### Page/View Inventory
[Each page: name | route path | key sections | interaction states]
[web-intro (Next.js App Router): note the app/ directory path and whether sections are server or client components, if it matters for design decisions]
[web-manager (Vite SPA): note React Router path structure]

### Component Hierarchy
[Shared components that appear across 2+ pages]

### Data Requirements
[has_api_spec=true → "API → UI Mapping: 각 엔드포인트가 어떤 페이지 상태/prop에 매핑되는지"]
[has_api_spec=false → "API.md 미제공 — 페이지 이름/컴포넌트 기반 추론된 데이터 필드:
  예) DashboardPage: 주문 건수(orderCount), 매출(revenue), ...
  실제 API 연동 시 수정이 필요할 수 있습니다."]
```

Close with: **"이 구조로 Figma에 그려드릴까요? 수정이 필요하면 말씀해주세요."**

## Step 3 — Wait for Approval

Do not call Figma until the user explicitly confirms. Phrases that mean "yes, proceed":
- "이 구조로 그려줘" / "그대로 그려줘" / "ok" / "진행해줘" / "좋아" / "맞아"

If the user requests changes ("홈 화면에 검색 바 추가해줘"), update the proposal in-place and show it again. Repeat until an approval phrase is received.

## Step 4 — Generate Figma Screens

> Reminder: This step generates Figma frames only. Do not write or scaffold any code file.

After approval:

1. Load `/figma-generate-design` skill — mandatory prerequisite before any Figma MCP call
2. Read `{app}/figma.config.json` for the `figmaFile` URL and target node-id:
   - `prac-fe-app-driver` → node-id `8-2`
   - `prac-fe-app-user` → node-id `0-1`
   - `prac-fe-web-manager` → node-id `8-3`
   - `prac-fe-web-intro` → node-id `8-4`
3. For **each screen/page** in the approved inventory:

   **Mobile**: 
   a. Create a frame of exactly **390 × 844 px** — never use 375×667 or any other size
   b. Design content within the safe content zone: top padding 59px, bottom padding 34px
   c. After the screen content is complete, overlay the Safe Area component (key: `00bfa96bea64def82819c61edd40191f09294123`) at x=0, y=0 on the frame

   **Web**:
   a. Create a frame of exactly **1440 × 900 px**
   b. No Safe Area overlay — use the full frame area for content
   c. Apply standard web layout conventions (navigation bar at top, content area, footer as appropriate)

4. Add screens as children of the target node — do not create a new Figma file
5. Position screens on the canvas with 100px spacing between them (e.g., x=0, x=1540, x=3080…)

## Step 5 — Close with Approval Gate

After generation:

```
Figma 링크: [url]

검토 후:
  수정이 필요하면 → "이 화면 수정해줘"
  승인하면        → "구현 시작해줘" 또는 "코드 작성해줘"
```

**HARD STOP. This skill ends here.**
Do NOT write code. Do NOT scaffold files. Do NOT call any code generation tool.
The next phase (code implementation) begins only when the user explicitly says "구현 시작해줘" or "코드 작성해줘" in a new message — never automatically.

---

## Dry-Run Mode

Triggered by: `"확인만 해줘"`, `"dry-run"`, `"미리 보기만"`

Run Steps 0–2 only. Output `[DRY-RUN]` at the top. Do not call Figma.

```
[DRY-RUN] Figma 호출 없이 설계 제안만 출력합니다.

## Design Proposal — [App Name]

### Frame Standard
[Mobile: 모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px]
[Web: 데스크탑 프레임: 1440×900 | Safe Area 없음]

...
```

---

## Isolation Rule

Only access files inside the detected target app's directory. Never read files from a different app's directory. For example, when designing for `prac-fe-app-driver`, do not access `prac-fe-web-manager/` or any other app directory.
