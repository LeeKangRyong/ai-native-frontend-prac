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

Bridges the app's design spec files (.ai/) to Figma screens with a human approval gate in between. The key principle: read what was specified, synthesize a coherent proposal, confirm the structure with a low-fidelity wireframe in Figma, get the human's sign-off, *then* apply the full design. This order matters — hi-fi design is expensive to revise, so confirming structure first in a wireframe prevents wasted work.

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

## Step 0.5 — Figma 페이지 현황 파악

앱이 감지되면 대상 Figma 페이지의 현재 상태를 읽는다. 이 정보는 이후 모든 생성/배치 단계의 기준이 된다.

수집 항목:
1. **기존 프레임 목록** — 이름, 위치(x/y), 크기(w/h)
2. **진행 상황 분류** — 각 화면을 아래 3가지 상태 중 하나로 분류:
   - `완료` — `{화면명}` 하이파이 프레임 존재 (WF 여부 무관)
   - `와이어프레임 완료` — `[WF] {화면명}` 프레임만 존재, 하이파이 없음
   - `미착수` — 해당 화면 프레임 없음
3. **캔버스 점유 영역** — 기존 프레임 전체의 최대 x + width 값 → 신규 프레임의 시작 x 좌표 산출

배치 기준:
- 와이어프레임 행: y = 0, x는 기존 `[WF]` 프레임 끝 좌표 + 100px
- 하이파이 행: y = 1000, x는 동일 화면의 와이어프레임과 같은 x 좌표
- 기존 프레임이 없으면 x = 0 에서 시작

이미 완료된 화면은 건너뛴다. 사용자가 명시적으로 "다시 그려줘" / "덮어써줘" 라고 하지 않는 한 기존 프레임을 수정하거나 덮어쓰지 않는다.

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
- Proceed normally through Steps 2–6

## Step 2 — Synthesize Design Proposal

Output a structured proposal **before touching Figma**. The template branches by platform. This is cheap to revise; Figma is not.

### Mobile proposal template

```
## Design Proposal — [App Name]

### Frame Standard
모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px

### Design Tokens
[Colors, typography, spacing from DESIGN.md. If empty, show "미정 (DESIGN.md 작성 필요)"]

### Figma 진행 현황
[완료 (건너뜀): 화면명1, 화면명2, ...]
[와이어프레임 완료 → 하이파이 진행 예정: 화면명3, ...]
[미착수 → 와이어프레임부터 시작: 화면명4, ...]

### Data Requirements
[has_api_spec=true → 주요 엔드포인트와 매핑 화면 이름만 간략히]
[has_api_spec=false → "API.md 미제공 — 추론된 주요 데이터 필드 (화면명: 필드명, ...)"]
```

### Web proposal template

```
## Design Proposal — [App Name]

### Frame Standard
데스크탑 프레임: 1440×900 | Safe Area 없음 (브라우저 환경)
[web-intro only: 반응형 브레이크포인트가 DESIGN.md에 지정된 경우 나열]

### Design Tokens
[Colors, typography, spacing from DESIGN.md. If empty, show "미정 (DESIGN.md 작성 필요)"]

### Figma 진행 현황
[완료 (건너뜀): 페이지명1, 페이지명2, ...]
[와이어프레임 완료 → 하이파이 진행 예정: 페이지명3, ...]
[미착수 → 와이어프레임부터 시작: 페이지명4, ...]

### Data Requirements
[has_api_spec=true → 주요 엔드포인트와 매핑 페이지 이름만 간략히]
[has_api_spec=false → "API.md 미제공 — 추론된 주요 데이터 필드 (페이지명: 필드명, ...)"]
```

Close with: **"이 구조로 Figma에 와이어프레임을 그려드릴까요? 수정이 필요하면 말씀해주세요."**

## Step 3 — 프로포절 승인 대기

Do not call Figma until the user explicitly confirms. Phrases that mean "yes, proceed":
- "이 구조로 그려줘" / "그대로 그려줘" / "ok" / "진행해줘" / "좋아" / "맞아"

If the user requests changes ("홈 화면에 검색 바 추가해줘"), update the proposal in-place and show it again. Repeat until an approval phrase is received.

## Step 4 — Figma 와이어프레임 생성

> Reminder: This step generates wireframe frames only. Do not write or scaffold any code file.

1. Load `/figma-generate-design` skill — mandatory prerequisite before any Figma MCP call
2. Read `{app}/figma.config.json` for the `figmaFile` URL and target node-id
3. **와이어프레임 스타일** — 디자인 토큰 적용 없이 레이아웃 구조만 표현:

   | 요소 | 스타일 |
   |---|---|
   | 배경 | `#FFFFFF` |
   | 컨테이너/카드 | `#E8E8E8` fill, `#CCCCCC` stroke 1px |
   | 이미지 플레이스홀더 | `#C4C4C4` fill + 대각선 X 표시 |
   | 제목 텍스트 | 실제 레이블, `#333333`, Bold |
   | 본문 텍스트 영역 | 회색 가로줄 블록, `#AAAAAA` |
   | 버튼 | `#DDDDDD` fill + 실제 버튼 레이블 |
   | 아이콘 영역 | `#CCCCCC` 정사각형 박스 |

4. **프레임 명명**: `[WF] {화면명}` (예: `[WF] 홈화면`, `[WF] 주문상세`)
5. **배치**: Step 0.5에서 산출한 와이어프레임 행(y=0) 기준 x 좌표에 100px 간격으로 배치
6. **이미 `[WF]` 프레임이 존재하는 화면은 건너뜀** — 덮어쓰지 않음
7. **와이어프레임 완료 상태인 화면**(`[WF]` 있고 하이파이 없음)은 Step 4를 건너뛰고 Step 6으로 직행

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
      — 와이어프레임에서도 Safe Area 경계를 명확히 표시 (디자인 레퍼런스 전용, 코드에 구현하지 않음)

   **Web**:
   a. 프레임 크기 1440 × 900 px
   b. TopNav, 사이드바, 컨텐츠 영역을 회색 박스로 구분

8. 생성 완료 후 출력:
```
와이어프레임을 Figma에 그렸습니다.
링크: [url]

레이아웃 구조를 확인해주세요:
  수정이 필요하면 → "이 화면 수정해줘" (구체적으로 설명)
  승인하면        → "이 구조로 디자인해줘" 또는 "ok"
```

## Step 5 — 와이어프레임 승인 대기

와이어프레임 승인 전까지 Step 6에 진입하지 않는다.

수정 요청 시: 해당 `[WF]` 프레임만 업데이트 후 링크 재공유. 전체 재생성 불필요.

Phrases that mean "yes, proceed to hi-fi":
- "이 구조로 디자인해줘" / "ok" / "좋아" / "진행해줘" / "맞아"

## Step 6 — Figma 하이파이 디자인 생성

> Reminder: This step generates hi-fi Figma frames only. Do not write or scaffold any code file.

승인된 와이어프레임 구조를 기반으로 디자인 토큰을 적용한 하이파이 프레임을 생성한다.

1. 승인된 `[WF] {화면명}` 프레임의 레이아웃 구조(컴포넌트 위치/크기)를 레이아웃 기준으로 사용
2. 디자인 토큰(색상/타이포그래피/그림자/반경) 적용
3. **프레임 명명**: `{화면명}` (WF 접두사 없음, 예: `홈화면`, `주문상세`)
4. **배치**: 동일 화면의 `[WF]` 프레임과 같은 x 좌표, y = 1000 행에 배치
5. **이미 하이파이 프레임이 존재하는 화면은 건너뜀** — 사용자가 명시적으로 "덮어써줘" 하지 않는 한
6. 대상 node-id의 자식으로 추가:
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

## Step 7 — Close with Approval Gate

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

## Design Proposal — [App Name]

### Frame Standard
[Mobile: 모든 화면: 390×844 (iPhone 14) | Safe Area top 59px / bottom 34px]
[Web: 데스크탑 프레임: 1440×900 | Safe Area 없음]

### Figma 진행 현황
[Step 0.5 결과 요약 — 완료/와이어프레임 완료/미착수 화면 목록]

### 이번 작업 예정
[와이어프레임 생성 예정 화면 (미착수) | 하이파이 직행 예정 화면 (와이어프레임 완료)]

...
```

---

## Isolation Rule

Only access files inside the detected target app's directory. Never read files from a different app's directory. For example, when designing for `prac-fe-app-driver`, do not access `prac-fe-web-manager/` or any other app directory.
