---
name: figma-style-guide
description: >-
  이 모노레포의 4개 앱에서 Figma 캔버스에 'Style Guide' 섹션을 즉시 생성하는 스킬.
  앱의 .ai/DESIGN.md를 참고용으로 읽은 뒤 Colors / Typography / Spacing / Border Radius /
  Shadows / Components 6개 섹션으로 구성된 스타일 가이드 프레임을 승인 없이 바로 그린다.
  DESIGN.md가 비어있어도 항상 동일한 구조로 생성되며 값이 없는 항목은 플레이스홀더로 표시된다.
  Trigger for Korean: "스타일 가이드 그려줘", "스타일 가이드 만들어줘", "style guide 그려줘",
  "style guide 만들어줘", "디자인 토큰 figma에 그려줘", "컬러 팔레트 그려줘",
  "스타일 가이드 시작해줘", "style guide 시작해줘", "스타일가이드 그려줘".
  Trigger for English: "draw style guide", "create style guide", "generate style guide",
  "draw design tokens in figma", "style guide in figma", "make a style guide".
  사용자가 Figma에 스타일 가이드나 디자인 토큰을 그려달라고 하면 반드시 이 스킬을 먼저 호출할 것.
---

# figma-style-guide

앱의 디자인 토큰과 공통 컴포넌트를 한눈에 볼 수 있는 Style Guide 프레임을 Figma에 바로 그린다. 제안이나 승인 단계 없이 실행되며, `.ai/DESIGN.md`에 적힌 값이 있으면 그 값을 쓰고 없으면 플레이스홀더로 채운다.

> **DESIGN-ONLY BOUNDARY**
> 소스 코드 파일을 생성하거나 수정하지 않는다. Figma 프레임 생성만 수행한다.

## Step 0 — 대상 앱 감지

| 앱 | Figma node-id |
|---|---|
| prac-fe-app-driver | 8-2 |
| prac-fe-app-user | 0-1 |
| prac-fe-web-manager | 8-3 |
| prac-fe-web-intro | 8-4 |

감지 우선순위:
1. **CWD**: 현재 디렉터리가 4개 앱 폴더 중 하나이면 그 앱 사용
2. **명시적 언급**: 사용자가 앱을 직접 명시한 경우
3. **모호한 경우**: "driver, user, web-manager, web-intro 중 어느 앱의 스타일 가이드를 그릴까요?" 질문

## Step 1 — Figma 현황 확인

`{app}/figma.config.json`의 `codeConnect.figmaFile` URL을 읽어 대상 Figma 페이지를 확인한다.

- **`Style Guide` 프레임이 이미 존재하면**: "이미 Style Guide 프레임이 있습니다. 덮어쓸까요?" 를 물어본다. 사용자가 "덮어써줘" / "다시 그려줘"라고 하지 않으면 중단한다.
- **없으면**: Step 2로 진행

캔버스 배치:
- 위치: **x=0, y=2200** (WF 행 y=0 / 하이파이 행 y=1000과 겹치지 않음)
- 프레임명: `Style Guide — {앱 이름}`

## Step 2 — DESIGN.md 읽기

`{app}/.ai/DESIGN.md`를 읽는다. 파일이 없거나 비어있어도 오류 없이 진행한다.

DESIGN.md는 **참고용**이다. 구조를 파싱하려 하지 말고, 색상 코드·폰트명·스케일 수치 등 눈에 보이는 값이 있으면 그것을 사용한다. 값이 없는 항목은 `미입력` 플레이스홀더로 표시한다.

**폰트 감지**: DESIGN.md에 폰트명이 명시되어 있으면 메모해 둔다. Pretendard, Noto Sans KR, 나눔고딕 등 한국어 전용 폰트는 Figma 웹 폰트 목록에 없어 그리는 과정에서 Inter로 자동 대체된다. 이런 폰트가 있으면 Step 4 완료 메시지에 그 사실을 알린다.

## Step 3 — Style Guide 생성

1. `/figma-generate-design` 스킬 로드 — Figma MCP 호출 전 필수
2. 감지된 앱의 node-id 하위에 `Style Guide — {앱 이름}` 프레임 생성

### 캔버스 레이아웃

최상위 프레임 `Style Guide — {앱 이름}`:
- **위치**: x=0, y=2200
- **배경**: `#F7F8FA`
- `layoutMode: VERTICAL`, `primaryAxisSizingMode: AUTO`, `clipsContent: false`
- 내부 섹션을 세로로 쌓아 배치한다 (섹션 간 간격 80px, 패딩 64px)
- 각 섹션은 **섹션 제목 (28px Bold, #191F28)** + 콘텐츠 영역으로 구성

**모든 섹션 컨테이너 프레임에 공통 적용:**
- `layoutMode: VERTICAL`
- `primaryAxisSizingMode: AUTO` — 내용 높이에 맞춰 자동 확장, 절대 고정 높이 사용 금지
- `clipsContent: false` — 내용이 잘리지 않도록 반드시 설정
- 섹션 제목과 콘텐츠 사이 간격: 24px

---

### Colors 섹션

DESIGN.md에서 색상 토큰(이름과 값)을 읽어 스와치 카드를 가로로 나열한다.

스와치 행 컨테이너 프레임:
- `layoutMode: HORIZONTAL`, `layoutWrap: WRAP` (카드가 많으면 줄바꿈)
- `primaryAxisSizingMode: AUTO`, `counterAxisSizingMode: AUTO`
- `clipsContent: false` — 필수, 없으면 스와치가 잘림
- 카드 간격 16px (가로), 줄 간격 24px (세로)

각 스와치 카드:
- 80×80px 정사각형, 해당 색상으로 채움, 8px radius
- 아래에 토큰명 (12px SemiBold, #191F28)
- 그 아래 헥스값 (12px Regular, #8B95A1)

색상 값이 없으면: `#E5E8EB` 스와치에 토큰명 + "미입력" 표시

---

### Typography 섹션

DESIGN.md의 Font-Scale 수치와 Font-Family를 읽어 크기별 샘플 행을 세로로 나열한다.

각 행:
- 크기 레이블 (12px Regular, #8B95A1): 예) "16px"
- 샘플 텍스트 (해당 크기, Regular): "가나다 Aa 123"
- 샘플 텍스트 (해당 크기, Bold): "가나다 Aa 123"

Font-Scale이 없으면: 12 / 14 / 16 / 20 / 24 기본값으로 표시

---

### Spacing 섹션

DESIGN.md의 Spacing 수치를 읽어 시각적 바로 표시한다.

각 항목:
- 수치 레이블 (12px Regular, #8B95A1): 예) "16px"
- 시각 바: 높이 12px, 너비 = 해당 px 값, 색상 `#3182F6`, 4px radius

Spacing이 없으면: 4 / 8 / 12 / 16 / 24 / 32 기본값

---

### Border Radius 섹션

DESIGN.md의 Border-Radius 수치를 읽어 도형으로 비교한다.

각 카드:
- 80×80px 정사각형, `#E5E8EB` 배경, 해당 radius 적용
- 아래에 radius 값 (12px Regular, #8B95A1): 예) "12px"
- 카드 간격 16px

값이 없으면: 0 / 4 / 8 / 12 / 16 / 100(circle) 기본값

---

### Shadows 섹션

DESIGN.md의 shadow 토큰을 읽어 카드로 표시한다.

각 카드:
- 200×80px, `#FFFFFF` 배경, 해당 shadow 적용, 12px radius
- 아래에 토큰명 (12px Regular, #8B95A1)
- 카드 간격 24px

shadow 값이 없으면: `0 2px 12px rgba(0,0,0,0.08)` 예시 카드 1개

---

### Components 섹션

DESIGN.md의 Component 항목을 참고해 주요 UI 컴포넌트를 시각적으로 표시한다. 값이 있으면 해당 스타일로, 없으면 플레이스홀더로 그린다. 컴포넌트는 가로로 나열한다 (간격 24px).

표시할 컴포넌트:
- **Button (Primary)**: 160×48px 사각형, primary color 또는 `#3182F6` 배경, 12px radius. 중앙에 "Button" 텍스트 (14px Bold, 흰색).
- **Button (Secondary)**: 160×48px 사각형, 투명 배경, 1px `#3182F6` 테두리, 12px radius. 중앙에 "Button" 텍스트 (14px, `#3182F6`).
- **Card**: 200×100px 사각형, `#FFFFFF` 배경, 12px radius, `0 2px 8px rgba(0,0,0,0.08)` shadow. 우측 하단에 "Card" 레이블 (12px Regular, #8B95A1).
- **Avatar**: 40×40px 원형 (`#E5E8EB` 배경). 바로 우측에 48px 원형 (`#D1D6DB` 배경) 추가로 크기 비교.

---

## Step 4 — 완료 메시지

아래 메시지를 출력한다.

```
Style Guide를 Figma에 그렸습니다.
링크: [url]

DESIGN.md에 값을 채우면 이 스킬을 다시 실행해 업데이트할 수 있습니다.
```

DESIGN.md에서 Figma 미지원 폰트(Pretendard, Noto Sans KR 등)를 발견했다면 아래 줄을 추가한다:

```
⚠️ {폰트명} 폰트는 Figma 웹 폰트에 없어 Inter로 대체되었습니다. Figma에서 직접 교체하거나 Figma Plugin을 통해 설치할 수 있습니다.
```

**HARD STOP. 소스 코드를 생성하거나 수정하지 않는다.**
