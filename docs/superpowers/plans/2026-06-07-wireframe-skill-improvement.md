# figma-wireframe-from-spec 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `figma-wireframe-from-spec` 스킬에 화면 계획 확정 단계를 추가하고, Safe Area를 코드 수준에서 강제하며, 섹션을 2x 여유 너비로 생성한다.

**Architecture:** 단일 파일 `.claude/skills/figma-wireframe-from-spec/SKILL.md`의 Step 2 전체 교체 + Step 3 섹션 계산 수정 + Step 4 Safe Area 상수 블록 추가. 3개의 독립적인 Edit 작업으로 구성된다.

**Tech Stack:** Markdown (SKILL.md), Figma Plugin API (use_figma 코드 블록 내)

---

## File Structure

- **Modify**: `.claude/skills/figma-wireframe-from-spec/SKILL.md`
  - Step 2 전체 교체 (lines 109–145)
  - Step 3 섹션 크기 계산 1줄 수정 (line 196)
  - Step 4 상단에 Safe Area 상수 블록 삽입

---

## Task 1: Step 2 교체 — 화면 계획 확정 단계

**Files:**
- Modify: `.claude/skills/figma-wireframe-from-spec/SKILL.md` (Step 2 섹션 전체)

- [ ] **Step 1: 현재 Step 2 섹션 내용을 확인한다**

  파일의 `## Step 2` 섹션이 아래와 같이 시작하는지 확인:
  ```
  ## Step 2 — 플로우 그룹 구성 및 요약 출력
  ```
  끝은 `사용자 확인 후 Step 3으로 진행한다.` 로 끝남.

- [ ] **Step 2: Step 2 섹션 전체를 교체한다**

  아래 old_string → new_string 으로 Edit:

  **old_string** (SKILL.md의 `## Step 2` 전체):
  ```
  ## Step 2 — 플로우 그룹 구성 및 요약 출력

  ### 2-1. 플로우 그룹화

  필터링된 기능 목록에서 `상위 기능 ID` 값을 이용해 부모-자식 트리를 구성하고, 의미 단위로 묶는다.

  그룹화 규칙:
  1. `상위 기능 ID`가 `-` 또는 비어있는 기능 → **루트 기능** (독립 화면 또는 플로우 진입점)
  2. 루트가 아닌 기능은 `상위 기능 ID`를 따라가 최상위 루트에 귀속
  3. 복수 부모(쉼표 구분)는 첫 번째 부모 기준
  4. 의미론적으로 연관된 루트들은 하나의 플로우로 묶는다 (예: 회원가입+로그인 → `인증` 플로우)

  플로우명은 포함 기능들의 공통 목적을 짧게 명명한다 (예: `인증`, `메인`, `호출`, `정기호출`, `광고`).

  각 묶음은 3~4개 화면이 되도록 플로우 단위로 나눈다. 플로우 하나가 4개를 초과하면 앞뒤로 분할한다.

  ### 2-2. 요약 출력

  ```
  ## [TARGET] 와이어프레임 계획 (우선순위: [PRIORITY])

  총 [N]개 화면 / [M]개 플로우

  ### 플로우 목록
  1. [플로우명] — 화면명1, 화면명2, ...  ([N]개)
  2. [플로우명] — 화면명1, 화면명2, ...  ([N]개)
  ...

  ### 진행 순서
  묶음 1: [플로우명] (N개)
  묶음 2: [플로우명] (N개)
  ...

  이 순서로 Figma에 그릴까요? 수정이 필요하면 말씀해주세요.
  ```

  사용자 확인 후 Step 3으로 진행한다.
  ```

  **new_string** (교체할 내용):
  ````
  ## Step 2 — 화면 계획 확정

  xlsx의 **전체 컬럼**(기능명, 상위 기능 ID, 기능 상세설명 등 모든 컬럼)을 분석해 화면 목록을 도출하고, 사용자의 수정·확정을 받는다. **확정 전까지 Figma API를 호출하지 않는다.**

  ### 2-1. 화면 vs 컴포넌트 판별

  각 기능 행을 분석해 다음 중 하나로 분류한다:

  | 분류 | 기준 | 처리 |
  |---|---|---|
  | **독립 화면** | 사용자가 직접 이동하는 페이지 단위 기능 | `[WF]` 프레임으로 그림 |
  | **컴포넌트 화면** | 탭바·네비게이션바 등 여러 화면에 공통 등장하는 UI 요소인데 단독 WF로 표현할 필요가 있는 것 | `[WF]` 프레임으로 그리되 비고란에 "컴포넌트" 명시 |

  판별 기준:
  - `기능 상세설명`에 "모든 화면에서", "공통", "항상 표시" 등 표현 → 컴포넌트 화면 후보
  - `상위 기능 ID`가 없고 기능 자체가 네비게이션 요소(탭바, 헤더, 네비게이션바) → 컴포넌트 화면
  - 그 외 → 독립 화면

  ### 2-2. 플로우 그룹화

  필터링된 화면 목록에서 `상위 기능 ID`와 `기능 상세설명`을 바탕으로 의미 단위 플로우를 구성한다.

  그룹화 규칙:
  1. `상위 기능 ID`가 `-` 또는 비어있는 기능 → 루트 기능 (플로우 진입점)
  2. 루트가 아닌 기능은 최상위 루트에 귀속
  3. 의미론적으로 연관된 루트들은 하나의 플로우로 묶는다 (예: 회원가입+로그인 → `인증`)
  4. 플로우명은 포함 기능들의 공통 목적을 짧게 명명 (예: `인증`, `메인`, `호출`, `내비게이션`)

  ### 2-3. 화면 타이틀 도출

  기능명을 raw 그대로 화면 타이틀로 쓰지 않는다. `기능명` + `기능 상세설명`을 함께 읽어 사용자가 직관적으로 이해할 수 있는 타이틀을 만든다.

  예시:
  | 기능명 (raw) | 도출된 화면 타이틀 |
  |---|---|
  | `하단 탭바` | `[WF] 하단 탭바` (컴포넌트) |
  | `상단 네비게이션바` | `[WF] 상단 네비게이션바` (컴포넌트) |
  | `호출 기능 진입` | `[WF] 호출탭` |
  | `정기 예약 상세` | `[WF] 정기호출페이지` |

  ### 2-4. 주요 노출 요소 도출

  각 화면에서 **스크롤 없이 첫 화면에 보여야 할 요소**를 `기능 상세설명`과 상위-하위 기능 관계를 통해 도출한다.

  원칙:
  - 핵심 액션(버튼, 입력창)은 반드시 포함
  - 정보 표시 요소는 중요도 순으로 최대 5개
  - 스크롤 가능한 목록은 "리스트 (스크롤)"으로 단일 항목 표기

  ### 2-5. 화면 계획 출력 및 확정

  아래 형식으로 출력한다:

  ```
  ## [TARGET] 화면 구성 계획 (우선순위: [PRIORITY])

  총 N개 화면 / M개 플로우

  ### Flow 1: [플로우명]
  | # | 화면 타이틀              | 주요 노출 요소                                    | 비고 |
  |---|--------------------------|---------------------------------------------------|------|
  | 1 | [WF] 로그인              | 로고, 전화번호 입력, 로그인 버튼                  |      |
  | 2 | [WF] 회원가입            | 이름·전화번호 입력, 약관 동의, 가입 버튼          |      |

  ### Flow 2: [플로우명]
  | # | 화면 타이틀              | 주요 노출 요소                                    | 비고 |
  |---|--------------------------|---------------------------------------------------|------|
  | 3 | [WF] 상단 네비게이션바   | 뒤로가기, 화면 타이틀, 알림 아이콘                | 컴포넌트 |
  | 4 | [WF] 하단 탭바           | 탭 5개 (홈/호출/이용내역/혜택/마이)               | 컴포넌트 |

  수정하고 싶은 타이틀이나 요소가 있으면 알려주세요.
  (예: "3번 타이틀을 '네비게이션 컴포넌트'로", "1번에 '자동로그인 토글' 추가")
  확정이면 "확정"이라고 해주세요.
  ```

  사용자가 수정을 요청하면 해당 행을 업데이트한 뒤 테이블을 재출력한다.  
  사용자가 "확정"이라고 하면 Step 3으로 진행한다.

  > **확정된 화면 타이틀** → Step 4에서 `[WF] {화면 타이틀}` 프레임명으로 사용  
  > **확정된 주요 노출 요소** → Step 4 드로잉 시 "이 요소들을 스크롤 없이 한 화면에 배치"의 기준
  ````

- [ ] **Step 3: 변경 내용을 검토한다**

  파일을 열어 아래를 확인:
  - `## Step 2 — 화면 계획 확정` 헤더가 있는가
  - `확정 전까지 Figma API를 호출하지 않는다` 문구가 있는가
  - 테이블 출력 형식 (# | 화면 타이틀 | 주요 노출 요소 | 비고)이 있는가
  - Step 3 헤더(`## Step 3 — Wireframe 섹션 생성`)가 바로 이어지는가

- [ ] **Step 4: 커밋한다**

  ```bash
  git add .claude/skills/figma-wireframe-from-spec/SKILL.md
  git commit -m "chore(skill): figma-wireframe-from-spec Step2를 화면 계획 확정 단계로 교체"
  ```

---

## Task 2: Step 3 섹션 크기 2x 수정

**Files:**
- Modify: `.claude/skills/figma-wireframe-from-spec/SKILL.md` (섹션 크기 계산 1줄)

- [ ] **Step 1: 섹션 크기 계산 코드를 수정한다**

  아래 old_string → new_string 으로 Edit:

  **old_string:**
  ```
  maxScreensPerFlow = max(각 플로우의 화면 수)
  nFlows = 플로우 수
  SECTION_W = padding*2 + maxScreensPerFlow*(frameW+frameGap)
  SECTION_H = padding*2 + nFlows*(labelH+labelGap+frameH+flowGap)
  section.resizeWithoutConstraints(SECTION_W, SECTION_H)
  ```

  **new_string:**
  ```
  maxScreensPerFlow = max(각 플로우의 화면 수)
  nFlows = 플로우 수
  // 가로는 2x pre-allocate — figma-add-wireframe으로 화면 추가 시 섹션 재조정 불필요
  SECTION_W = padding*2 + (maxScreensPerFlow * 2) * (frameW + frameGap)
  SECTION_H = padding*2 + nFlows*(labelH+labelGap+frameH+flowGap)
  section.resizeWithoutConstraints(SECTION_W, SECTION_H)
  ```

- [ ] **Step 2: 변경 내용을 검토한다**

  파일에서 `SECTION_W` 줄이 `(maxScreensPerFlow * 2) * (frameW + frameGap)` 형태인지 확인.

- [ ] **Step 3: 커밋한다**

  ```bash
  git add .claude/skills/figma-wireframe-from-spec/SKILL.md
  git commit -m "chore(skill): figma-wireframe-from-spec 섹션 너비 2x pre-allocate"
  ```

---

## Task 3: Step 4 Safe Area 상수 블록 추가

**Files:**
- Modify: `.claude/skills/figma-wireframe-from-spec/SKILL.md` (Step 4 드로잉 코드 앞)

- [ ] **Step 1: Step 4 드로잉 섹션에 Safe Area 상수 블록을 삽입한다**

  `### 4-2. 섹션 내 배치 좌표` 앞의 `### 4-1. 묶음 처리` 내 `use_figma` 설명 바로 다음,
  `### 4-2. 섹션 내 배치 좌표` 헤더 위에 아래 내용을 삽입한다.

  **old_string:**
  ```
  ### 4-2. 섹션 내 배치 좌표

  섹션 내부의 각 플로우를 행으로 쌓는다:
  ```

  **new_string:**
  ````
  ### 4-2. Safe Area 상수 (Mobile 전용)

  **Mobile 화면(USER-APP, DRIVER-APP)을 그릴 때 반드시 아래 상수를 코드 최상단에 선언하고, 모든 요소 배치에 적용한다. 이 값을 절대 임의로 변경하지 않는다.**

  ```javascript
  // ⚠️ SAFE AREA CONSTANTS — 절대 변경 금지
  const SA = {
    CONTENT_TOP: 59,    // StatusBar 하단 — 콘텐츠 최상단 경계
    CONTENT_BOT: 810,   // HomeIndicator 상단 — 콘텐츠 최하단 경계
    HEADER_Y: 59,       // NavBar 시작 y
    HEADER_H: 44,       // NavBar 높이
    CONTENT_START: 103, // 헤더 있는 화면의 콘텐츠 시작 y (59 + 44)
    TABBAR_Y: 776,      // TabBar 시작 y
    TABBAR_H: 34,       // TabBar 높이 (776 + 34 = 810)
    FAB_MAX_Y: 776,     // FAB·플로팅 요소 최대 y
  };
  ```

  **요소 배치 검증 규칙 — 모든 요소에 적용:**
  ```javascript
  // 요소를 배치하기 전 반드시 확인
  // y >= SA.CONTENT_TOP AND y + height <= SA.CONTENT_BOT
  // 위반 시 → y를 경계값으로 클램핑
  const clampY = (y, h) => Math.max(SA.CONTENT_TOP, Math.min(y, SA.CONTENT_BOT - h));
  ```

  **화면 유형별 콘텐츠 y 범위:**

  | 화면 유형 | 콘텐츠 시작 y | 콘텐츠 끝 y | NavBar | TabBar |
  |---|---|---|---|---|
  | 인증/온보딩 | 59 | 810 | ❌ | ❌ |
  | 메인 (TabBar 있음) | 103 | 776 | ✅ y=59 | ✅ y=776 |
  | 서브 페이지 | 103 | 810 | ✅ 뒤로가기 | ❌ |
  | 컴포넌트 화면 | 59 | 810 | — | — |

  > Web(MANAGER-WEB, INTRO-WEB)은 Safe Area 없음 — 이 상수 블록 불필요.

  ### 4-3. 섹션 내 배치 좌표

  섹션 내부의 각 플로우를 행으로 쌓는다:
  ````

- [ ] **Step 2: 기존 `### 4-2. 섹션 내 배치 좌표` 헤더가 `### 4-3`으로 바뀌었는지 확인한다**

  파일에서 `### 4-3. 섹션 내 배치 좌표` 가 존재하고, `### 4-2. Safe Area 상수` 가 그 위에 있는지 확인.

- [ ] **Step 3: 기존 `### 4-3. 와이어프레임 스타일` 헤더 번호도 `### 4-4`로 업데이트한다**

  **old_string:**
  ```
  ### 4-3. 와이어프레임 스타일
  ```

  **new_string:**
  ```
  ### 4-4. 와이어프레임 스타일
  ```

- [ ] **Step 4: 변경 내용을 검토한다**

  파일에서 아래를 확인:
  - `### 4-2. Safe Area 상수 (Mobile 전용)` 헤더 존재
  - `const SA = {` 코드 블록 존재
  - `CONTENT_TOP: 59` 값 정확
  - `CONTENT_BOT: 810` 값 정확
  - `clampY` 함수 존재
  - 화면 유형별 y 범위 테이블 존재
  - `### 4-3. 섹션 내 배치 좌표` 헤더로 번호 변경됨
  - `### 4-4. 와이어프레임 스타일` 헤더로 번호 변경됨

- [ ] **Step 5: 커밋한다**

  ```bash
  git add .claude/skills/figma-wireframe-from-spec/SKILL.md
  git commit -m "chore(skill): figma-wireframe-from-spec Safe Area 상수 블록 및 검증 로직 추가"
  ```
