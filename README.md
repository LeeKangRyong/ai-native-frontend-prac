# AI Native한 Frontend 개발 연습 레포지토리

### 레포지토리 설명
하나의 서비스에 대해 4가지의 Frontend applicaton이 있다.  
- `prac-fe-app-driver`: 기사님들용 모바일 앱
- `prac-fe-app-user`: 사용자용 모바일 앱
- `prac-fe-web-management`: 관리자용 웹
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

`start-tmux.sh`를 통해 tmux 자동 세팅 및 세션 연결을 수행한다.

```
+------------------------+----------------------+
| 1                      | 3                    |
| prac-fe-app-user       | prac-fe-app-driver   |
+------------------------+----------------------+
| 2                      | 4                    |
| prac-fe-web-management | prac-fe-web-intro    |
+------------------------+----------------------+
```

<br>

- **github actions**

각각 push를 하면 다음 step을 통해 CI가 실행된다

**Flutter 앱** (`prac-fe-app-driver`, `prac-fe-app-user`)
```
1. Flutter stable 설치 (캐시)
2. flutter pub get --enforce-lockfile
3. flutter analyze
4. flutter test
```

**Web** (`prac-fe-web-management`, `prac-fe-web-intro`)
```
1. Node.js 20 설치 (package-lock.json 캐시)
2. npm ci
3. npm run lint
4. npm test
```

<br>

### Custom Skills
- **frontend-issue-publisher**

`.github\ISSUE_TEMPLATE\task_ex.md` 템플릿에 맞게 issue를 제작해주고 발행해주는 skill

사용자는 folder, label, 요구사항을 입력하면 된다.  
trigger는 `~~issue를 만들어줘` 등으로 설정돼있어, 해당 트리거를 첨부하면 자동으로 skill이 실행된다.