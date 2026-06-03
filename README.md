# AI Native한 Frontend 개발 연습 레포지토리

### 레포지토리 설명
하나의 서비스에 대해 4가지의 Frontend applicaton이 있다.  
- `prac-fe-app-driver`: 기사님들용 모바일 앱
- `prac-fe-app-user`: 사용자용 모바일 앱
- `prac-fe-web-manager`: 관리자용 웹
- `prac-fe-web-intro`: 서비스 소개 웹

Agentic workflow 환경 세팅 후 **CLAUDE CODE**를 통해 자동화된 FE 개발을 수행한다.

<br>

### 목표
한 명의 FE 개발자가 스케일이 큰 FE 작업을 자동화하여 혼자 개발할 수 있도록 한다.  
`claude --dangerously-skip-permission`를 걸어둬야 자동화할 수 있으므로, 각 서비스 간 간섭이 없도록 해야 한다.  
FE 개발 + 디자인을 24시간 돌리면서, 다른 작업을 수행할 수 있도록 한다. 

<br>

### 세팅
- `wsl` + `tmux`

프로젝트 경로: `/home/kangr/ai-native-frontend-prac`

`start-tmux.sh`를 통해 tmux 자동 세팅 및 세션 연결을 수행한다.

```
+------------------------+----------------------+
| 1                      | 3                    |
| prac-fe-app-user       | prac-fe-app-driver   |
+------------------------+----------------------+
| 2                      | 4                    |
| prac-fe-web-manager    | prac-fe-web-intro    |
+------------------------+----------------------+
```

<br>

- **github actions**

각각 push를 하면 다음 step을 통해 CI가 실행된다

**React Native 앱** (`prac-fe-app-driver`, `prac-fe-app-user`)
```
1. Node.js 20 설치 (package-lock.json 캐시)
2. npm ci
3. npm run lint
4. npx tsc --noEmit
5. npm test -- --watchAll=false
```

**Web** (`prac-fe-web-manager`, `prac-fe-web-intro`)
```
1. Node.js 22 설치 (package-lock.json 캐시)
2. npm ci
3. npm run lint
4. npm test -- --watchAll=false
```

<br>

### .ai/ 문서 구조

4개 앱 모두 `.ai/` 디렉토리를 가지며, AI 워크플로우의 컨텍스트 소스로 사용된다.  
스킬들이 이 파일들을 파싱하여 디자인 제안 및 코드 생성의 기반으로 사용한다.

| 파일 | 역할 |
|---|---|
| `API.md` | 엔드포인트, 데이터 구조 → TypeScript 타입 및 목 데이터 기반 |
| `DESIGN.md` | 디자인 토큰, 화면 목록, 컴포넌트 라이브러리 |
| `CONVENTIONS.md` | 폴더 구조, 네이밍 규칙 |
| `IMPLEMENTATION_SLOT.md` | Phase C 진입점 — 구현 하네스/goal의 입력 컨텍스트 및 완료 조건 정의 |

<br>

### Custom Skills

네 가지 skill이 있다. 각각 단독으로 사용할 수 있으며, 필요에 따라 `frontend-issue-publisher` → `figma-design-workflow` → `frontend-tdd-runner` → `frontend-commit-push` 순으로 조합할 수 있다.

- **`frontend-issue-publisher`**

  `.github/ISSUE_TEMPLATE/task_ex.md` 템플릿에 맞게 issue를 제작하고 발행하는 skill.  
  trigger: `~~issue를 만들어줘`, `이슈 등록해줘` 등

<br>

- **`figma-design-workflow`**

  `.ai/API.md`, `.ai/DESIGN.md`, `.ai/CONVENTIONS.md`를 파싱하여 디자인 제안을 구조화하고, 인간 승인 후 Figma MCP로 화면을 생성하는 skill.  
  모든 화면은 **390×844 (iPhone 14)** 기준으로 생성되며, Safe Area 오버레이를 자동 적용한다.  
  Figma 승인 후 "구현 시작해줘" / "코드 작성해줘" 입력 시 Phase C(구현)로 전환된다.  
  trigger: `디자인 시작해줘`, `figma 그려줘`, `화면 디자인해줘` 등

<br>

- **`frontend-tdd-runner`**

  지정된 서브앱의 전체 테스트 게이트를 실행하는 skill.  
  두 가지 모드로 동작한다:
  - **Validate-only** (기본): tsc → unit test → E2E 순서로 실행, 실패 시 에러 리포트만 출력 (agent spawn 없음)
  - **Auto-fix**: 실패 시 fix-agent가 자동 수정 후 재실행 (unit 최대 3회, E2E 최대 2회)  
  
  trigger: `테스트 돌려줘`, `TDD 검증해줘` (validate-only) / `테스트 고쳐줘`, `테스트 통과시켜줘` (auto-fix)

<br>

- **`frontend-commit-push`**

  lint → `frontend-tdd-runner` pre-flight 통과 후 AngularJS 컨벤션에 맞게 커밋하고 main에 직접 push하는 skill.  
  scope 자동 감지, 멀티 서브앱 변경 시 isolation 위반 경고, issue 번호 필수 검증.  
  trigger: `커밋하고 푸시해줘`, `작업 끝났으니 올려줘` 등