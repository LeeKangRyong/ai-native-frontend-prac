---
name: frontend-commit-push
description: >-
  Commit staged/working changes for one of this repo's four sub-apps and push
  them, following the team's AngularJS-style convention
  ([type]([scope]): 한글 제목 #이슈번호) and branch convention
  ([type]([scope])/#issue-desc). Runs the same pre-flight gate as CI
  (npm run lint → npx tsc --noEmit for apps → npm test) inside the affected
  sub-app before committing, auto-detects scope (driver/user/management/intro)
  from changed paths, and pushes to the feature branch — never to main, never
  creates a PR. Use this whenever the user wants to commit and/or push finished
  frontend work — especially Korean phrasings like "커밋하고 푸시해줘", "커밋해줘",
  "푸시해줘", "변경사항 커밋해줘", "작업 끝났으니 올려줘", "컨벤션대로 커밋해줘",
  "lint 돌리고 커밋해줘", "이슈 N번 작업 커밋해줘", "feat(user)로 커밋해줘 #12",
  or any phrasing like "commit my changes" / "commit and push". This is the
  natural follow-up step after frontend-issue-publisher. Do NOT use for issue
  creation (use frontend-issue-publisher) or PR operations — this project
  forbids PRs entirely; refuse such requests and explain why.
---

# Frontend Commit & Push

구현이 끝난 변경을 받아서, 컨벤션에 맞는 브랜치 위에서 → CI와 동일한 로컬 pre-flight를 통과시킨 뒤 → 컨벤션에 맞는 커밋 메시지로 커밋 → feature 브랜치로 push 한다. `frontend-issue-publisher`로 만든 이슈의 후속 단계다.

## 사전 준비 — 컨벤션을 매번 새로 읽기

`DEVELOPMENT.md`를 매 실행 시 읽어 type/scope 화이트리스트와 형식이 변경되지 않았는지 확인한다. 아래 내용은 현재 기준이며, 파일이 우선한다.

- **커밋 형식**: `[type]([scope]): [한글 제목 50자 이내] #[이슈번호]`
- **브랜치 형식**: `[type]([scope])/#[이슈번호]-[description]`
- **허용 type**: `feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`
- **허용 scope**: `driver, user, management, intro`

---

## Dry-run 모드

발화에 `dry-run`, `확인만 해줘`, `실행 말고 보여줘`, `미리 보기만` 중 하나가 포함되면 dry-run 모드로 동작한다.

- **단계 1~5는 그대로 실행**한다 (scope 판정, 브랜치 확인, pre-flight, 메시지 검증 모두 실제 실행).
- **단계 6에서 멈춘다**: `git commit`과 `git push`를 실행하지 않고, 대신 실행될 명령과 최종 커밋 메시지를 출력한다.
- 출력 형식:
  ```
  [DRY-RUN] 실제로는 실행하지 않음
  브랜치: feat(user)/#12-login-screen
  커밋 메시지: feat(user): 로그인 화면 구현 #12
  push 명령: git push -u origin feat(user)/#12-login-screen
  ```

---

## 단계 1 — 변경 범위 수집

`git status --porcelain`과 `git diff --name-only`(staged + unstaged), `git ls-files --others --exclude-standard`(신규 untracked)를 합쳐 변경 파일 전체를 확인한다.

변경이 없으면 즉시 안내하고 종료한다.

---

## 단계 2 — scope 자동 판정 + 격리 검증

각 파일의 최상위 디렉토리 세그먼트로 scope를 매핑한다:

| 디렉토리 | scope |
|---|---|
| `prac-fe-app-driver/` | `driver` |
| `prac-fe-app-user/` | `user` |
| `prac-fe-web-management/` | `management` |
| `prac-fe-web-intro/` | `intro` |

**판정 규칙:**

- **단일 서브앱** → scope 확정, 계속 진행.
- **2개 이상 서브앱**에 변경이 걸침 → 모노레포 격리 규칙 위반. 한 커밋은 한 서브앱만 포함해야 한다. 어느 서브앱을 지금 커밋할지 사용자에게 묻고, 나머지는 다음 커밋으로 분리하도록 안내한다.
- **서브앱 외 루트 파일만** 변경(예: `.github/`, 루트 `*.md`) → scope 자동 추정 불가. 사용자에게 scope를 명시 요청한다.
- 사용자 발화에 scope가 명시된 경우, 자동 판정과 불일치하면 경고 후 재확인한다. 사용자 의도를 우선하되 틀린 scope로 진행하지 않는다.

---

## 단계 3 — 브랜치 게이트

`git branch --show-current`로 현재 브랜치를 확인한다.

- **`main`이면**: 컨벤션 feature 브랜치를 생성하고 그쪽에서 작업한다. 브랜치명은 `[type]([scope])/#[이슈번호]-[desc]` (desc는 영문 kebab-case). type과 이슈번호가 아직 확정되지 않은 경우 단계 5에서 확정 후 생성해도 된다.
- **이미 feature 브랜치**면 그대로 사용한다.
- **main에 직접 커밋·push하지 않는다.**

---

## 단계 4 — 로컬 pre-flight 게이트

판정된 서브앱 디렉토리 안에서 CI와 **동일한 순서**로 실행한다. 하나라도 실패하면 이후 단계로 진행하지 않는다.

| 서비스 | Node | pre-flight 명령 |
|---|---|---|
| `prac-fe-app-driver` (driver) | 20 | `npm ci` → `npm run lint` → `npx tsc --noEmit` → `npm test` |
| `prac-fe-app-user` (user) | 20 | `npm ci` → `npm run lint` → `npx tsc --noEmit` → `npm test` |
| `prac-fe-web-management` (management) | 22 | `npm ci` → `npm run lint` → `npm test` |
| `prac-fe-web-intro` (intro) | 22 | `npm ci` → `npm run lint` → `npm test` |

웹 서비스(management/intro)는 CI에 type check 단계가 없으므로 `npx tsc --noEmit`을 **실행하지 않는다**.

**실패 처리:**
- 어느 단계든 비정상 종료 시 → 실패 로그 요약을 사용자에게 보고하고 커밋·push를 중단한다.
- `--no-verify`, `tsc --noEmit` 스킵, lint 자동 수정 등 우회는 절대 하지 않는다.
- 로컬 Node 버전이 CI 기준(20/22)과 다를 경우 결과가 달라질 수 있음을 한 줄 경고로 안내한다(차단까지는 하지 않음).
- 스크립트(`npm run lint` 등)가 `package.json`에 없으면 사실을 보고하고 진행 여부를 사용자에게 확인한다.

---

## 단계 5 — 커밋 메시지 조립·검증

`[type]([scope]): [한글 제목] #[이슈번호]` 형식으로 메시지를 만든다.

**검증 규칙:**

- **type**: 허용 목록(`feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`) 외 → 거부, 재입력 요청.
- **scope**: 단계 2에서 판정한 scope와 일치해야 한다.
- **한글 제목**: 50자 이내. 초과 시 줄여서 재확인.
- **이슈번호**: `#<숫자>` 필수. 발화·브랜치명·최근 이슈에서 추출을 시도하고, 찾지 못하면 **추측하지 않고** 사용자에게 질문한다.

---

## 단계 6 — 미리보기 → 확인 → 커밋 → push

최종 브랜치명, 커밋 메시지, 실행될 push 명령을 사용자에게 보여주고 명확한 승인을 받는다.

승인 후:

1. `git add` — 대상 서브앱 디렉토리로 범위를 제한한다.
2. `git commit -m "..."` — 확정된 메시지로 커밋.
3. `git push -u origin <branch>` — feature 브랜치로만 push한다.

성공 시 브랜치명과 커밋 해시를 사용자에게 보고한다.

**PR은 생성하지 않는다.** 사용자가 PR 생성·머지를 요청하면 거부하고 이유(프로젝트 규칙: PR 금지)를 안내한다.

---

## 예시

**예시 1 — 정상 (앱, user)**

```
이슈 12번 user 앱 로그인 화면 작업 끝났어. 커밋하고 푸시해줘.
```

처리 흐름: `prac-fe-app-user/**`만 변경 → scope=`user` → 현재 `main`이므로 `feat(user)/#12-login-screen` 브랜치 생성 → `prac-fe-app-user`에서 lint/tsc/test 통과 → 메시지 미리보기 `feat(user): 로그인 화면 구현 #12` → 승인 후 push.

**예시 2 — pre-flight 실패 (웹, management)**

```
management 변경 커밋해줘 #7
```

처리 흐름: scope=`management` → 웹이므로 tsc 스킵 → `npm run lint` 실패 → 커밋 중단, ESLint 출력 요약 보고. "lint를 수정한 뒤 다시 요청하라"로 종료.

**예시 3 — 이슈번호 누락**

```
지금 변경사항 커밋해줘
```

처리 흐름: 이슈번호를 발화·브랜치명에서 찾지 못함 → 추측하지 않고 사용자에게 이슈번호 질문. 확인 전 커밋하지 않음.
