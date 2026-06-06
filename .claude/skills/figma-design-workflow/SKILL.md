---
name: figma-design-workflow
description: >-
  MANDATORY skill — invoke when the user wants to apply hi-fi design to an
  existing [WF] {기능명} wireframe in Figma, for any of the 4 apps in this monorepo.
  Do NOT use the frontend-design skill for this project.
  Requires an existing [WF] {기능명} frame in Figma as a prerequisite.
  Reads the wireframe layout, synthesizes a hi-fi design proposal, then applies
  full design tokens after approval. To create a wireframe first, use figma-add-wireframe.
  Trigger for Korean: "[WF] {기능명} 디자인해줘", "[WF] {기능명} 디자인해달라",
  "[WF] {기능명} 디자인해주세요", "[WF] {기능명} 기반으로 디자인해줘",
  "와이어프레임 기반으로 디자인해줘", "WF 보고 디자인해줘",
  "WF 기반 디자인 시작해줘", "{기능명} 하이파이 그려줘",
  "[WF] {기능명} 하이파이로 만들어줘", "디자인 적용해줘".
  Trigger for English: "design from wireframe", "hi-fi from [WF]",
  "apply design to wireframe", "design based on WF",
  "turn wireframe into design", "[WF] {feature} design".
---

# figma-design-workflow

Converts an existing `[WF] {기능명}` wireframe into a fully designed hi-fi Figma screen with a human approval gate in between. The key principle: read the existing wireframe layout, synthesize a coherent hi-fi design proposal, confirm the approach with the human, *then* apply the full design. Wireframe creation is a separate concern handled by the `figma-add-wireframe` skill.

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

## Step 0 — Detect Target App and Feature Name

Determine which of the 4 apps the task is for, classify its platform, and extract the target feature name.

| App | Platform | Stack | Figma node-id |
|---|---|---|---|
| prac-fe-app-driver | mobile | React Native (Expo) | 8-2 |
| prac-fe-app-user | mobile | React Native (Expo) | 0-1 |
| prac-fe-web-manager | web | React + Vite SPA | 8-3 |
| prac-fe-web-intro | web | Next.js (App Router) | 8-4 |

Detection priority (highest to lowest):
1. **CWD first**: If the working context is inside one of the 4 app directories, use that app.
2. **Explicit mention**: If the user's request names an app directly, use that.
3. **Recently modified files**: If CWD is the repo root and no app is named, look at which app directory had the most recent file changes.
4. **Ambiguous fallback**: If still unclear, ask: "driver, user, web-manager, web-intro 중 어느 앱의 디자인을 시작할까요?"

Set `platform = "mobile"` for driver/user, `platform = "web"` for manager/intro.

**Feature name extraction**:
Extract `target_feature` from the trigger phrase:
- `"[WF] 결제수단선택 디자인해줘"` → `target_feature = "결제수단선택"`
- `"[WF] 홈화면 하이파이로 만들어줘"` → `target_feature = "홈화면"`
- If no feature name is explicitly stated, ask: "어떤 기능의 와이어프레임을 하이파이로 디자인할까요?"

## Step 0.5 — Figma 페이지 현황 파악

앱이 감지되면 대상 Figma 페이지의 현재 상태를 읽는다.

수집 항목:
1. **기존 프레임 목록** — 이름, 위치(x/y), 크기(w/h)
2. **진행 상황 분류** — 각 화면을 아래 3가지 상태 중 하나로 분류:
   - `완료` — `{화면명}` 하이파이 프레임 존재 (WF 여부 무관)
   - `와이어프레임 완료` — `[WF] {화면명}` 프레임만 존재, 하이파이 없음
   - `미착수` — 해당 화면 프레임 없음
3. **캔버스 점유 영역** — 기존 프레임 전체의 최대 x + width 값 참고

**[WF] 존재 확인 — 필수 체크**:
- `[WF] {target_feature}` 프레임이 Figma 페이지에 존재하는지 확인
- 존재하지 않으면:
  ```
  "[WF] {target_feature}" 프레임을 Figma에서 찾을 수 없습니다.
  먼저 figma-add-wireframe 스킬로 와이어프레임을 그려주세요.
  ```
  → **스킬 종료**

배치 기준:
- 하이파이 행: `[WF] {target_feature}` 프레임과 같은 x 좌표, y = WF 프레임 y + 1000
- 이미 하이파이 프레임(`{target_feature}`)이 존재하면 건너뜀 — 사용자가 명시적으로 "덮어써줘" 하지 않는 한

## Step 1 — Read Design Spec Files

Attempt to read all available files in parallel from the detected app's `.ai/` directory:

| File | Status | Purpose |
|---|---|---|
| `.ai/API.md` | **Optional** | Data structures, endpoints → what UI needs to display |
| `.ai/CONVENTIONS.md` | Preferred | Naming rules, folder structure, component patterns |
| `.ai/DESIGN.md` | Preferred | Screen/page list, design tokens, component library |

**IMPORTANT**: Read ONLY files under the `.ai/` directory. Do NOT read `src/`, `app/`, `components/`, or any other source code files — this skill operates from specs and user intent alone, not from existing code. **When no code exists yet**: this is the expected state. Missing `.ai/` files or empty spec files are handled by inference (Step 2). Never fail or pause because source code doesn't exist.

**API.md is optional.** If the file does not exist or is empty, do not treat it as an error — skip it silently and set `has_api_spec = false`. When it is missing, infer data display needs from:
- Screen/component names in `DESIGN.md`
- Component and naming patterns in `CONVENTIONS.md`
- Any data context the user explicitly mentioned in their request

If `CONVENTIONS.md` or `DESIGN.md` is empty or contains only template comments, note it briefly and continue.

**When DESIGN.md is empty AND the user specifies a style reference** (e.g., "TOSS 디자인으로 해줘", "카카오 스타일로"):
- Treat the named brand/style as the design token source
- In the proposal, document inferred design tokens based on that brand's known design system
- Mark these tokens as `[추론됨 — {brand} 디자인 시스템 기반]`
- Proceed normally through Steps 2–4

## Step 2 — Synthesize Design Proposal

Output a structured proposal **before touching Figma**. This is cheap to revise; Figma is not.

### Mobile proposal template

```
## Design Proposal — [App Name] / [WF] {target_feature}

### Frame Standard
모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px

### Design Tokens
[Colors, typography, spacing from DESIGN.md. If empty, show "미정 (DESIGN.md 작성 필요)"]

### Figma 진행 현황
[완료 (건너뜀): 화면명1, 화면명2, ...]
[와이어프레임 완료 → 하이파이 진행 예정: {target_feature}, ...]

### Data Requirements
[has_api_spec=true → 주요 엔드포인트와 매핑 화면 이름만 간략히]
[has_api_spec=false → "API.md 미제공 — 추론된 주요 데이터 필드 (화면명: 필드명, ...)"]
```

### Web proposal template

```
## Design Proposal — [App Name] / [WF] {target_feature}

### Frame Standard
데스크탑 프레임: 1440×900 | Safe Area 없음 (브라우저 환경)
[web-intro only: 반응형 브레이크포인트가 DESIGN.md에 지정된 경우 나열]

### Design Tokens
[Colors, typography, spacing from DESIGN.md. If empty, show "미정 (DESIGN.md 작성 필요)"]

### Figma 진행 현황
[완료 (건너뜀): 페이지명1, 페이지명2, ...]
[와이어프레임 완료 → 하이파이 진행 예정: {target_feature}, ...]

### Data Requirements
[has_api_spec=true → 주요 엔드포인트와 매핑 페이지 이름만 간략히]
[has_api_spec=false → "API.md 미제공 — 추론된 주요 데이터 필드 (페이지명: 필드명, ...)"]
```

Close with: **"[WF] {target_feature} 와이어프레임을 기반으로 이 방향으로 하이파이 디자인을 그려드릴까요? 수정이 필요하면 말씀해주세요."**

## Step 3 — 프로포절 승인 대기

Do not call Figma until the user explicitly confirms. Phrases that mean "yes, proceed":
- "이 방향으로 그려줘" / "그대로 그려줘" / "ok" / "진행해줘" / "좋아" / "맞아"

If the user requests changes, update the proposal in-place and show it again. Repeat until an approval phrase is received.

## Step 4 — Figma 하이파이 디자인 생성

> Reminder: This step generates hi-fi Figma frames only. Do not write or scaffold any code file.

승인된 `[WF] {target_feature}` 프레임의 레이아웃 구조를 기반으로 디자인 토큰을 적용한 하이파이 프레임을 생성한다.

1. Load `/figma-generate-design` skill — mandatory prerequisite before any Figma MCP call
2. Read `{app}/figma.config.json` for the `figmaFile` URL and target node-id
3. `[WF] {target_feature}` 프레임의 레이아웃 구조(컴포넌트 위치/크기)를 레이아웃 기준으로 사용
4. 디자인 토큰(색상/타이포그래피/그림자/반경) 적용
5. **프레임 명명**: `{target_feature}` (WF 접두사 없음, 예: `홈화면`, `결제수단선택`)
6. **배치**: `[WF] {target_feature}` 프레임과 같은 x 좌표, y = WF 프레임 y + 1000
7. **이미 하이파이 프레임이 존재하는 경우 건너뜀** — 사용자가 명시적으로 "덮어써줘" 하지 않는 한
8. 대상 node-id의 자식으로 추가:
   - `prac-fe-app-driver` → node-id `8-2`
   - `prac-fe-app-user` → node-id `0-1`
   - `prac-fe-web-manager` → node-id `8-3`
   - `prac-fe-web-intro` → node-id `8-4`

   **Mobile**:
   a. 프레임 크기 390 × 844 px
   b. **Safe Area 콘텐츠 배치 규칙 — 반드시 준수**:
      - 모든 콘텐츠 요소의 y 범위: **59 이상, 810 이하** (이 범위를 벗어나면 안 됨)
      - Header/NavBar: y = 59 고정
      - TabBar: y = 776 고정 (높이 34px → 하단 y=810까지)
      - ScrollView 콘텐츠 시작: y = 59 + HeaderHeight
      - FAB/Floating 요소: y ≤ 776
      - y < 59 또는 y > 810 구간에는 어떤 콘텐츠 요소도 배치하지 않음
   c. Safe Area 컴포넌트 (key: `00bfa96bea64def82819c61edd40191f09294123`) 를 x=0, y=0에 오버레이

   **Web**:
   a. 프레임 크기 1440 × 900 px
   b. Safe Area 오버레이 없음
   c. 표준 웹 레이아웃 적용 (상단 내비게이션, 콘텐츠 영역, 푸터)

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

> **⚠️ Safe Area 구현 주의사항**
> Figma의 Safe Area 오버레이 컴포넌트는 **디자인 레퍼런스 전용**입니다.
> 코드에서 Safe Area 경계선을 시각적으로 렌더링하지 마세요.
> 실제 Safe Area 처리는 `react-native-safe-area-context`의 `SafeAreaView` 또는 `useSafeAreaInsets` 훅으로 처리합니다.

---

## Dry-Run Mode

Triggered by: `"확인만 해줘"`, `"dry-run"`, `"미리 보기만"`

Run Steps 0–2 only (Figma 호출 없음). Output `[DRY-RUN]` at the top.

```
[DRY-RUN] Figma 호출 없이 설계 제안만 출력합니다.

## Design Proposal — [App Name] / [WF] {target_feature}

### Frame Standard
[Mobile: 모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px]
[Web: 데스크탑 프레임: 1440×900 | Safe Area 없음]

### Figma 진행 현황
[Step 0.5 결과 요약 — 완료/와이어프레임 완료 화면 목록]

### 이번 작업 예정
[하이파이 진행 예정: {target_feature}]

...
```

---

## Isolation Rule

Only access files inside the detected target app's directory. Never read files from a different app's directory. For example, when designing for `prac-fe-app-driver`, do not access `prac-fe-web-manager/` or any other app directory.
