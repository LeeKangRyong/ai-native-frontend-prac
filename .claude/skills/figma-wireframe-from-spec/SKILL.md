---
name: figma-wireframe-from-spec
description: >-
  docs_secret/requirements.xlsx의 기능명세서를 읽고 지정한 앱과 우선순위에 해당하는
  와이어프레임 전체를 Figma에 플로우 단위로 그려주는 스킬.
  3~4개씩 묶어 순차 배치하고 묶음마다 사용자 확인을 받으며, 완료 후 화면별 수정 루프를 제공한다.

  TRIGGER: 사용자가 requirements.xlsx나 기능명세서를 언급하며 Figma 와이어프레임을 요청할 때 반드시 이 스킬을 사용한다.
  "기능명세서로 와이어프레임 그려줘", "requirements.xlsx 보고 figma 그려줘",
  "USER-APP 와이어프레임 만들어줘", "DRIVER-APP 와이어프레임 그려줘",
  "MANAGER-WEB 와이어프레임", "INTRO-WEB 와이어프레임",
  "기능명세서 figma 그려줘", "스펙 보고 wireframe 그려줘",
  "requirements에서 와이어프레임", "spec 기반 와이어프레임".
---

# figma-wireframe-from-spec

`docs_secret/requirements.xlsx`의 기능명세서를 읽어, 지정한 앱과 우선순위의 화면들을 플로우 단위로 묶고 Figma에 와이어프레임으로 그린다. 3~4개 묶음씩 그리면서 사용자 확인을 받고, 끝나면 수정 루프로 이어진다.

> **DESIGN-ONLY BOUNDARY**  
> 소스 코드 파일을 생성하거나 수정하지 않는다. Figma 프레임 생성만 수행한다.

---

## Step 0 — 입력 수집

사용자 메시지에서 아래 두 값을 추출한다. 누락된 값이 있으면 묻는다.

| 입력 | 선택지 |
|---|---|
| **TARGET** | `USER-APP` / `DRIVER-APP` / `MANAGER-WEB` / `INTRO-WEB` |
| **PRIORITY** | `상` / `중` / `하` |

---

## Step 1 — 기능명세서 파싱

### 1-1. 파일 위치 탐색

아래 순서로 파일을 찾는다:

1. `docs_secret/requirements.xlsx` (모노레포 루트 CWD)
2. `../docs_secret/requirements.xlsx` (서브 프로젝트 CWD)

찾은 경로로 아래 Python 스크립트를 `wsl -e python3 -c "..."` 또는 `python3 -c "..."` 로 실행한다:

```python
import zipfile, xml.etree.ElementTree as ET, json

def parse_xlsx(path):
    with zipfile.ZipFile(path) as z:
        ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
        with z.open('xl/sharedStrings.xml') as f:
            ss_tree = ET.parse(f)
        strings = [
            si.text or ''.join(t.text or '' for t in si.iter(f'{{{ns}}}t'))
            for si in ss_tree.findall(f'.//{{{ns}}}si')
        ]
        with z.open('xl/workbook.xml') as f:
            wb_tree = ET.parse(f)
        sheets = [
            (s.get('name'), s.get('sheetId'))
            for s in wb_tree.findall(f'.//{{{ns}}}sheet')
        ]
        result = {}
        for sheet_name, sheet_id in sheets:
            with z.open(f'xl/worksheets/sheet{sheet_id}.xml') as f:
                ws_tree = ET.parse(f)
            rows = []
            for row in ws_tree.findall(f'.//{{{ns}}}row'):
                row_data = []
                for c in row.findall(f'{{{ns}}}c'):
                    t = c.get('t')
                    v_el = c.find(f'{{{ns}}}v')
                    val = ''
                    if v_el is not None:
                        val = strings[int(v_el.text)] if t == 's' else (v_el.text or '')
                    row_data.append(val)
                if any(row_data):
                    rows.append(row_data)
            result[sheet_name] = rows
    return result

import sys
data = parse_xlsx(sys.argv[1])
print(json.dumps(data, ensure_ascii=False))
```

### 1-2. 시트 선택 및 필터링

TARGET에 따라 기능명세서 시트를 찾는다:

| TARGET | 시트명 (우선) | 폴백 시 요구사항명세서 대분류 |
|---|---|---|
| USER-APP | `사용자용 앱 기능명세서` | `사용자용 앱` |
| DRIVER-APP | `기사용 앱 기능명세서` | `기사용 앱` |
| MANAGER-WEB | `관리자용 웹 기능명세서` | `관리자용 웹` |
| INTRO-WEB | `회사소개용 웹 기능명세서` | `회사소개용 웹` |

해당 시트가 없으면 `요구사항명세서` 시트를 폴백으로 사용한다. 이 경우 각 행을 독립된 화면 1개로 취급한다.

**헤더 행(row[0])을 읽어 컬럼 인덱스를 동적으로 파악한다.** 기능명세서 시트의 헤더는 보통:
`요구사항 ID | 기능 ID | 상위 기능 ID | 우선순위 | 기능명 | 기능 상세설명 | ...`

우선순위 컬럼 값이 PRIORITY와 일치하는 행만 추출한다 (`상` / `중` / `하`).

---

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

---

## Step 3 — Wireframe 섹션 생성

### 3-1. Figma 대상 페이지

| TARGET | node-id (URL 표기) | node-id (Plugin API) | Platform |
|---|---|---|---|
| USER-APP | `0-1` | `0:1` | mobile |
| DRIVER-APP | `8-2` | `8:2` | mobile |
| MANAGER-WEB | `8-3` | `8:3` | web |
| INTRO-WEB | `8-4` | `8:4` | web |

Figma 파일: `https://www.figma.com/design/OyVl4OeOau122rlTfo1Tg3/DRT`

### 3-2. 섹션 생성

**반드시 `figma:figma-use` 스킬을 로드한 뒤 `use_figma`를 호출한다. 이 순서를 절대 건너뛰지 않는다.**

```javascript
// 대상 페이지로 이동
const targetPage = figma.root.children.find(p => p.id === 'PAGE_NODE_ID');
if (targetPage) await figma.setCurrentPageAsync(targetPage);

// 기존 'Wireframe' 섹션 확인
let section = figma.currentPage.children.find(
  n => n.type === 'SECTION' && n.name === 'Wireframe'
);
if (!section) {
  section = figma.createSection();
  section.name = 'Wireframe';
  section.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];

  // 기존 프레임 아래 배치 (기본값 y=3500)
  const existing = figma.currentPage.children.filter(n => 'y' in n && 'height' in n);
  const maxY = existing.reduce((m, f) => Math.max(m, f.y + f.height), 0);
  section.x = 0;
  section.y = maxY > 200 ? maxY + 200 : 3500;
}
```

**섹션 크기 계산** (전체 화면 수 N 기준):

- Mobile: `frameW=390, frameH=844, frameGap=60, flowGap=120, labelH=40, labelGap=16, padding=80`
- Web: `frameW=1440, frameH=900, frameGap=80, flowGap=160, labelH=40, labelGap=16, padding=80`

```
maxScreensPerFlow = max(각 플로우의 화면 수)
nFlows = 플로우 수
SECTION_W = padding*2 + maxScreensPerFlow*(frameW+frameGap)
SECTION_H = padding*2 + nFlows*(labelH+labelGap+frameH+flowGap)
section.resizeWithoutConstraints(SECTION_W, SECTION_H)
```

---

## Step 4 — 배치 루프 (묶음별 순차 진행)

### 4-1. 묶음 처리

각 묶음에 대해:

1. **`figma:figma-use` 스킬 로드** → `use_figma` 호출
2. 묶음의 화면들을 섹션 내에 배치 (아래 4-2, 4-3 규칙 적용)
3. 완료 후 출력:

```
[묶음 N/M] '[플로우명]' 와이어프레임을 그렸습니다.
화면: 화면명1, 화면명2, ...

다음 묶음([다음 플로우명])을 계속 그릴까요? (y/n)
```

사용자가 `n`이면 "y로 재개하거나 Step 5(수정 단계)로 넘어갈 수 있습니다."라고 안내하고 대기한다.

### 4-2. 섹션 내 배치 좌표

섹션 내부의 각 플로우를 행으로 쌓는다:

```javascript
const PADDING = 80;
let currentY = PADDING;

for (const flow of currentBatch) {
  // 플로우 레이블 (텍스트 노드, 16px Bold, #555555)
  const label = figma.createText();
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  label.characters = flow.name;
  label.fontSize = 16;
  label.fills = [{ type: 'SOLID', color: { r: 0.33, g: 0.33, b: 0.33 } }];
  label.x = section.x + PADDING;
  label.y = section.y + currentY;
  currentY += LABEL_H + LABEL_GAP;

  // 화면 프레임들 (좌 → 우)
  let currentX = PADDING;
  for (const screen of flow.screens) {
    // 이미 [WF] 프레임이 있으면 건너뜀
    const exists = figma.currentPage.children.some(n => n.name === `[WF] ${screen.name}`);
    if (!exists) {
      const frame = drawWireframeFrame(screen, section.x + currentX, section.y + currentY);
      section.appendChild(frame);
    }
    currentX += FRAME_W + FRAME_GAP;
  }
  currentY += FRAME_H + FLOW_GAP;
}
```

### 4-3. 와이어프레임 스타일

레이아웃 구조만 표현하며 디자인 토큰을 적용하지 않는다.

| 요소 | 스타일 |
|---|---|
| 프레임 배경 | `#FFFFFF` |
| 컨테이너/카드 | `#E8E8E8` fill, `#CCCCCC` 1px stroke |
| 이미지/지도 플레이스홀더 | `#C4C4C4` fill |
| 제목 텍스트 | 실제 레이블, `#333333`, Bold |
| 본문 텍스트 영역 | `#AAAAAA` 가로줄 블록 (height 12px, 너비 다양) |
| 버튼 | `#DDDDDD` fill + 실제 레이블 텍스트 |
| 아이콘 영역 | `#CCCCCC` 정사각형/원형 박스 |
| 입력 필드 | `#FFFFFF` fill + `#CCCCCC` 1px 테두리, 48px 높이 |

**프레임 명명**: `[WF] {기능명}` (예: `[WF] 회원가입`, `[WF] 호출페이지`)

**Mobile NavBar / TabBar 배치 기준** (USER-APP, DRIVER-APP):

| 화면 유형 | 해당 화면 예시 | NavBar | TabBar |
|---|---|:---:|:---:|
| 인증/온보딩 | 회원가입, 로그인 | ❌ | ❌ |
| 메인 영역 | 메인 페이지, 이용기록탭, 탑승현황탭, 호출탭, 정기호출탭, 상단 네비게이션바, 하단 탭바 | ✅ | ✅ |
| 서브 페이지 | 호출페이지, 정기호출페이지, 차량호출, 회원정보수정, 회원탈퇴 | ✅ 뒤로가기 | ❌ |

- **인증 화면**: SafeArea(y=0~59) 이후 y=75부터 콘텐츠 시작. NavBar/TabBar 없음.
- **메인 영역**: NavBar rect (y=59, h=44, `#FFFFFF`, 하단 1px `#E8E8E8` stroke) + TabBar rect (y=776, h=68, `#FFFFFF`, 상단 1px `#E8E8E8` stroke, 탭 아이콘 5개 placeholder). 콘텐츠 y 범위: 103~776.
- **서브 페이지**: NavBar rect (y=59, h=44) + 좌측 `←` 뒤로가기 placeholder 텍스트. TabBar 없음. 콘텐츠 y 범위: 103~810.
- **NavBar 타이틀 텍스트 없음** — 타이틀은 콘텐츠 영역 내 별도 텍스트로 표현.
- Safe Area 오버레이 컴포넌트 (`key: 00bfa96bea64def82819c61edd40191f09294123`) 를 x=0, y=0에 적용

**Web 추가 규칙** (MANAGER-WEB, INTRO-WEB):
- 프레임 크기: 1440×900px
- TopNav, 사이드바, 콘텐츠 영역을 회색 박스로 구분

---

## Step 5 — 수정 루프

모든 묶음 완료 후:

```
모든 와이어프레임이 완성되었습니다!

수정하고 싶은 화면이 있으면 화면명을 알려주세요.
(예: "회원가입, 호출페이지, 탑승현황탭")
없으면 "없음" 또는 "완료"라고 말씀해주세요.
```

사용자가 화면명을 제공하면:

```
다음 각 화면을 어떻게 수정할지 설명해주세요:
- [화면명1]:
- [화면명2]:
```

수정 지시를 받으면 해당 `[WF] {화면명}` 프레임만 업데이트한다 (`figma:figma-use` 로드 후 `use_figma` 호출).  
수정 완료 후 다시 수정할 화면을 묻는다. 사용자가 "없음" / "완료" / "끝"이라고 하면 종료한다.

---

## 완료 메시지

```
와이어프레임이 완성되었습니다.
Figma 링크: [url]

디자인 작업이 필요하면 → "디자인 시작해줘"
구현이 필요하면       → "구현 시작해줘"
```

**HARD STOP. 소스 코드를 생성하거나 수정하지 않는다.**
