---
name: frontend-issue-publisher
description: >-
  Create and publish a GitHub issue from this repo's Frontend Task template
  (.github/ISSUE_TEMPLATE/task_ex.md), then open it on GitHub with `gh`. Use
  this whenever the user wants to turn a description of frontend work into a
  GitHub issue — especially Korean phrasings like "이슈 만들어줘", "~~ issue를
  만들어줘", "태스크 이슈 작성해줘", "이슈로 등록해줘", or when they give a
  folder/label/description block (e.g. "folder: prac-fe-app-user / label:
  feature / ...설명") describing a task for one of the four sub-apps
  (prac-fe-app-driver, prac-fe-app-user, prac-fe-web-management,
  prac-fe-web-intro). Trigger even if they don't say the word "template" — any
  request to file, open, write, or publish an issue for this repo should use
  this skill so the issue matches the team's format and conventions.
---

# Frontend Issue Publisher

Turn a short request into a well-structured GitHub issue that follows this
repo's `task_ex.md` template, then publish it with `gh issue create`. The point
is consistency: every issue should read like the others on the board, be scoped
to exactly one of the four sub-apps, and carry technical detail that's grounded
in that sub-app's actual stack — not generic boilerplate.

## What the user gives you

A free-form request, often shaped like this:

```
folder: prac-fe-app-user
label: feature

알림에서 toss의 overlay 라이브러리를 사용해서 모달을 효율적으로 띄우는 issue를 만들어줘
```

Pull these out (some may be missing — see below):

- **folder** — which sub-app the work belongs to. One of `prac-fe-app-driver`,
  `prac-fe-app-user`, `prac-fe-web-management`, `prac-fe-web-intro`.
- **label** — issue label(s) like `feature`, `bug`, `task`, `refactor`.
- **story** — a reference to a parent story (`#42`, a URL, "스토리 12"). Only
  link a story when the user actually provides one; never invent a number.
- **the task itself** — the natural-language description of what to build.

If **folder** is missing, try to infer it from the description (e.g. mentions of
React Native/driver/user app vs. admin web vs. intro site), but if it's genuinely
ambiguous, ask — guessing wrong puts the issue on the wrong board.

## Workflow

### 1. Read the template fresh

Read `.github/ISSUE_TEMPLATE/task_ex.md` every time rather than relying on
memory — the team may change it. The template has two parts:

- **Frontmatter** (the `---` block): carries the `title` prefix (`[TASK-FE] `),
  the `folder` field, and the default `labels`. Keep this block at the top of
  the issue you publish, filling in `title`, `folder`, and `labels` for this
  request. The `folder` field is the canonical place the target sub-app is
  recorded — it is **not** a GitHub label (see step 5).
- **Body** (everything below the frontmatter): the section skeleton you fill in.

Preserve the template's exact section headings verbatim, including the
`(Optional)` suffixes (e.g. `## 기술적 고려사항(Optional)`). The team prefers the
published issue to mirror the template as-is.

### 2. Ground yourself in the target stack

Read `<folder>/CLAUDE.md` for the sub-app you're filing against. This matters a
lot: the four apps are **not** the same stack.

| Folder | Stack |
|---|---|
| prac-fe-app-driver | React Native (Expo) / TypeScript |
| prac-fe-app-user | React Native (Expo) / TypeScript |
| prac-fe-web-management | React + Vite / TypeScript |
| prac-fe-web-intro | Next.js / TypeScript |

This is why grounding matters: a request might name a library that doesn't fit
the stack (e.g. a web-only library that has no React Native equivalent). When
that happens, don't blindly copy the library in. Note the mismatch and suggest
the stack-appropriate equivalent, so the issue is actually actionable for
whoever picks it up.

### 3. Fill in every section

Write the issue body in **Korean**, matching the template's tone. Keep the exact
heading text and order from the template. Section-by-section:

- **태스크 설명** — Expand the one-line request into 2–4 concrete sentences: what
  to build, where, and the user-facing intent. Resolve vagueness using the
  stack context, but don't pad.
- **관련 스토리** — If the user gave a story, write `- Part of #<번호>` (use a full
  repo-qualified link like `owner/repo#번호` for a story in another repo). If
  they didn't, leave the section's guidance comment and omit the bullet rather
  than writing a fake `#스토리번호`.
- **구현 사항** — A checklist of 3–6 concrete, stack-appropriate steps derived
  from the task. These are the actual implementation moves, not restatements of
  the title.
- **테스트 요구사항** — Keep the template's checkboxes, and make the optional
  scenarios real: write 1–2 scenarios that fit this task. Match the stack
  (Flutter `widget test` vs. React Testing Library, etc.).
- **완료 조건** — Keep the template defaults as-is unless the task calls for more.
- **기술적 고려사항 (Optional)** — Real considerations for *this* stack:
  libraries to use, state/lifecycle concerns, edge cases, performance. When a
  specific library or API is involved, add the official doc link here (see
  step 4). This is also where you flag any stack mismatch from step 2.
- **관련 자료 (Optional)** — Links to official docs, design references, or API
  specs that help the implementer. Omit the section's placeholder if you have
  nothing genuine to add — empty boilerplate is worse than no section.

### 4. Add reference links when they genuinely help (optional)

If the task names a library, framework feature, or API, do a quick web search to
find the **official** documentation URL and drop it into 기술적 고려사항 or 관련
자료. One or two high-quality links beat a pile of marginal ones. Skip this
entirely for trivial tasks — don't manufacture links to fill space.

### 5. Build the title, folder, and labels

- **Title**: `[TASK-FE] <간결한 한글 요약>` — a tight summary of the task, using
  the template's prefix.
- **Folder**: put the target sub-app in the frontmatter `folder` field. This is
  where the sub-app belongs — never as a label. (The user typically gives it on
  a `folder:` line precisely because it's a separate axis from labels.)
- **Labels**: the template's default label (`task`) plus the user's label(s)
  only — e.g. `task`, `feature`. Do **not** add the folder/sub-app name to the
  labels. Labels must already exist or `gh issue create` will fail, so check
  with `gh label list` and create any genuinely missing one with
  `gh label create "<name>"` (confirm with the user before creating new labels).

### 6. Preview, confirm, then publish

Publishing creates a real issue others will see, so show the user the full
rendered issue first — title, labels, and body — and get a clear go-ahead before
creating it.

Then publish. Write the full issue (frontmatter block with `folder` filled in,
followed by the body) to a temp file — Korean + markdown survives much better
through `--body-file` than through shell-escaped `--body`. Detect the repo from
git, and create:

```bash
REPO=$(git -C <repo-root> remote get-url origin | sed -E 's#.*github.com[:/]([^/]+/[^/.]+)(\.git)?#\1#')
gh issue create \
  --repo "$REPO" \
  --title "[TASK-FE] ..." \
  --body-file /tmp/issue-body.md \
  --label task --label feature
```

Note the folder (e.g. `prac-fe-app-user`) is **not** passed as a `--label`; it
lives in the body's frontmatter `folder` field.

`gh` may be invoked as `gh` (if on PATH) or via its full install path
(`"C:\Program Files\GitHub CLI\gh.exe"` on this machine). If `gh` reports the
user isn't logged in, stop and tell them to run `gh auth login` once — you can't
do the browser auth for them. On success, report the issue URL back to the user.

## Example

**Input:**
```
folder: prac-fe-web-management
label: feature

대시보드에서 React Query로 주문 목록을 서버 상태로 캐싱하고 무한 스크롤 붙이는 이슈 만들어줘
```

**Resulting title:** `[TASK-FE] 대시보드 주문 목록 React Query 캐싱 및 무한 스크롤`

**Folder:** `prac-fe-web-management` (in the frontmatter `folder` field).
**Labels:** `task`, `feature` (the folder is *not* a label).

**Body (abridged):** 태스크 설명 describes caching the order list as server state
and adding infinite scroll on the management dashboard; 구현 사항 lists concrete
React Query steps (`useInfiniteQuery`, `getNextPageParam`, intersection-observer
trigger, cache invalidation); 기술적 고려사항 links the TanStack Query docs and
notes Vite/React specifics.
