---
name: figma-add-wireframe
description: >-
  Use this skill whenever the user wants to draw or add a new wireframe frame
  to an existing Figma page in this monorepo. The user describes what to draw
  in their prompt; this skill handles reading existing [WF] frames, proposing
  where in the flow the new frame belongs, getting approval, and drawing it in
  a style consistent with existing wireframes.
  Trigger for Korean: "[WF] {기능명} 그려줘", "와이어프레임 추가해줘",
  "[WF] 추가해줘", "와이어프레임 그려줘", "{기능명} 와이어프레임 만들어줘",
  "와이어프레임 새로 그려줘", "{기능명} WF 그려줘".
  Trigger for English: "add wireframe", "draw wireframe", "create [WF]",
  "new wireframe for {feature}", "draw a wireframe".
  Prerequisite: target Figma page must already exist (created by figma-design-workflow
  or manually). This skill does NOT create Figma pages — it adds frames to them.
---

# figma-add-wireframe

Adds a new `[WF] {기능명}` wireframe frame to an existing Figma page. The user tells you what to draw in their prompt; this skill reads the existing wireframes on the page to match their style, proposes a placement in the user flow, gets approval, and then draws.

> **WIREFRAME-ONLY BOUNDARY**
> This skill produces **Figma wireframe frames only**. It MUST NOT generate, scaffold, or modify any source code file. It MUST NOT apply design tokens or produce hi-fi output — that is the job of `figma-design-workflow`.

## Step 0 — Detect Target App

Determine which of the 4 apps the task is for.

| App | Platform | Figma node-id |
|---|---|---|
| prac-fe-app-driver | mobile | 8-2 |
| prac-fe-app-user | mobile | 0-1 |
| prac-fe-web-manager | web | 8-3 |
| prac-fe-web-intro | web | 8-4 |

Detection priority:
1. **CWD**: if inside one of the 4 app directories, use that app
2. **Explicit mention** in the user's request
3. **Ambiguous fallback**: ask "driver, user, web-manager, web-intro 중 어느 앱에 와이어프레임을 추가할까요?"

Set `platform = "mobile"` for driver/user, `platform = "web"` for manager/intro.

Also extract from the user's prompt:
- `feature_name`: the name of the feature/screen (e.g., "결제수단선택")
- `draw_spec`: the user's description of what to draw (e.g., "상단 헤더, 카드/계좌 선택 리스트, 하단 확인 버튼")

## Step 1 — Read Existing Figma Page State

Load `/figma-use` skill first — mandatory before any Figma call.

**All wireframe frames live inside a Figma SECTION.** This skill always reads from and writes to that section — never directly to the page root.

### 1-A. Find the Wireframe SECTION

Scan the target page for a SECTION node that contains `[WF]` frames. This section is typically named `"Wireframe"` but may have a different name — identify it by its children, not its name.

- If found → record `wf_section_id` (the SECTION's node ID) and `wf_section_bounds` (x/y/w/h of the section on the canvas)
- If NOT found → create a new SECTION named `"Wireframe"` at x=0, y=0 with an initial size large enough for one frame (e.g., 490 × 944 for mobile). Record its node ID as `wf_section_id`.

All subsequent reads and writes use `wf_section_id` as the parent — never the page-level node-id directly.

### 1-B. Collect frame data inside the SECTION

From within the SECTION, collect:

1. **Existing [WF] frame list** — names, positions (x/y relative to section), sizes (w/h), sorted by x ascending
2. **Flow sequence** — left-to-right x order represents the user flow:
   e.g., `[WF] 로그인` → `[WF] 홈` → `[WF] 주문목록` → `[WF] 주문상세`
3. **Style pattern** — from the most complete [WF] frame:
   - fill colors, stroke colors
   - header/tabbar presence and height
   - content layout type (card / list / grid / form)
   - spacing and padding values
   - gap between frames
4. **HiFi offset** — if hi-fi frames also exist in the section, record the y difference between a `[WF]` frame and its paired hi-fi frame

If no `[WF]` frames exist in the section yet, skip style extraction and use the default style table in Step 3.

## Step 2 — Propose Placement

Before drawing anything, propose where the new `[WF] {feature_name}` frame belongs in the flow.

Show the user a short table:

```
현재 플로우:
  [WF] 로그인 → [WF] 홈 → [WF] 주문목록 → [WF] 주문상세

제안 삽입 위치:
  [WF] 주문상세 오른쪽에 [WF] {feature_name} 추가
  근거: {한 줄 이유 — 어떤 플로우 흐름에 따라 이 위치를 선택했는지}

이 위치로 진행할까요? 다른 위치를 원하시면 말씀해주세요.
```

Do not call Figma to draw until the user confirms. Phrases that mean "yes, proceed":
- "ㄱㄱ" / "ok" / "진행해줘" / "좋아" / "그 위치로 그려줘" / "맞아"

If the user requests a different position, update the proposal and re-show it.

**Middle insertion case**: If the new frame logically belongs between two existing frames (not at the end of the flow), present two options:

```
옵션 A — 플로우 중간 삽입:
  [WF] 홈 → [WF] 주문목록 → [WF] {feature_name} → [WF] 주문상세
  ※ 기존 [WF] 주문상세의 x 좌표를 오른쪽으로 이동합니다.

옵션 B — 플로우 끝에 추가:
  [WF] 홈 → [WF] 주문목록 → [WF] 주문상세 → [WF] {feature_name}
  ※ 기존 프레임 이동 없음.

어느 위치로 진행할까요? (A / B / 다른 위치를 직접 말씀해주세요)
```

If the user chooses option A (middle insertion), move the displaced frames right by `(frame_width + gap)` before placing the new frame. Update the section bounds accordingly.

## Step 3 — Draw the Wireframe

After approval, draw `[WF] {feature_name}` using the user's `draw_spec` as the layout guide.

### Style — two paths

**[Path A] Existing [WF] frames present:**
Apply the style pattern extracted in Step 1. The goal is that the new wireframe looks like it belongs in the same set — same gray tones, same spacing rhythm, same header/footer treatment. Use `draw_spec` to determine the content sections; use the extracted pattern for how each section looks.

**[Path B] No existing [WF] frames (first wireframe on this page):**
Use the default wireframe style:

| Element | Style |
|---|---|
| Background | `#FFFFFF` |
| Container / Card | `#E8E8E8` fill, `#CCCCCC` stroke 1px |
| Image placeholder | `#C4C4C4` fill + diagonal X mark |
| Title text | actual label, `#333333`, Bold |
| Body text area | gray horizontal line blocks, `#AAAAAA` |
| Button | `#DDDDDD` fill + actual button label text |
| Icon area | `#CCCCCC` square box |

### Frame naming

Always: `[WF] {feature_name}`
Examples: `[WF] 결제수단선택`, `[WF] 주문상세`, `[WF] 홈`

### Placement

All coordinates are **relative to the Wireframe SECTION's internal space**.

- **parent**: `wf_section_id` (the SECTION node found/created in Step 1 — never the page root node-id)
- **x**: right edge of the last [WF] frame in the section + gap (use extracted gap, fallback 100px)
- **y**: match the y of existing [WF] frames inside the section (fallback y = 50 to give top padding inside the section)
- Do NOT overwrite existing `[WF]` frames — skip silently unless the user said "덮어써줘"

**Section bounds expansion**: After placing the new frame, check if it fits within `wf_section_bounds`. If the new frame's right edge (x + frame_width) exceeds the section's current width, expand the section to contain it (add 100px right padding). This prevents frames from escaping the section boundary.

### Platform-specific rules

**Mobile (prac-fe-app-driver, prac-fe-app-user)**:
- Frame size: 390 × 844 px
- All content y range: **59 ≤ y ≤ 810** — nothing outside this band
  - Header/NavBar: y = 59
  - TabBar: y = 776 (height 34px → bottom at y = 810)
  - ScrollView content starts at: y = 59 + HeaderHeight
  - FAB / floating elements: y ≤ 776
- Overlay Safe Area component (key: `00bfa96bea64def82819c61edd40191f09294123`) at x=0, y=0 after drawing — for design reference only, not for code

**Web (prac-fe-web-manager, prac-fe-web-intro)**:
- Frame size: 1440 × 900 px
- No Safe Area overlay
- Divide into: TopNav area (gray box), main content area, footer if applicable

## Step 4 — Confirm

After drawing, output:

```
[WF] {feature_name} 와이어프레임을 Figma에 추가했습니다.
링크: [url]

레이아웃을 확인해주세요:
  수정이 필요하면 → "이 화면 수정해줘" (구체적으로)
  하이파이 디자인으로 넘어가려면 → "[WF] {feature_name} 디자인해줘"
```

**HARD STOP.** Do not generate code. Do not apply design tokens. Do not proceed to hi-fi automatically.

---

## Isolation Rule

Only access files inside the detected target app's directory. Never read files from a different app's directory.
