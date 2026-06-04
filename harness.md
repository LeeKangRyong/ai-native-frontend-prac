# 하네스 에이전트 시스템 전체 파이프라인 (코드 리뷰 포함)
## 단계
### 1. 플랜 작성 및 검증 반복 (Planning & Review Loop)
Planner ➔ Critic ➔ Planner ➔ Critic ➔ ...

Planner가 .ai/DESIGN.md 및 IMPLEMENTATION_SLOT.md를 기반으로 모노레포 규칙(Absolute Isolation 등)을 반영한 작업 명세서(Task Breakdown)를 작성합니다.

Critic이 해당 플랜이 컨벤션과 아키텍처에 부합하는지 검증하고 반려 또는 승인합니다.

최종 승인: Critic이 만족하면 해당 플랜을 최종 Plan으로 확정하고 공유 컨텍스트(HarnessContext)에 저장합니다.

### 2. 코딩 (Coding Phase)
Coder가 확정된 최종 Plan의 스텝(Task 단위)에 맞게 실제 코드를 작성합니다.

이때 TypeScript 타입 선언, 컴포넌트, 비즈니스 로직, 그리고 .stories.tsx(스토리북 파일)까지 플랜의 기준에 맞게 순차적으로 구현합니다.

### 3. 소스코드 정적 검증 및 교정 (Static Quality Gate)
Coder ➔ Critic ➔ Analyzer ➔ Coder ➔ ...

코딩이 완료되면 Critic이 코드를 정적으로 분석합니다.

검증 항목: 타 서브앱 디렉토리 import 여부(Isolation 검증), Safe Area 누락 여부 등.

반려 시: Analyzer가 컨벤션 위반 원인을 정밀 분석하여 가이드라인을 작성하고, Coder가 이를 바탕으로 코드를 재수정합니다. Critic이 승인할 때까지 반복합니다.

### 4. 코드 리뷰 단계 (Code Review Gate)
Reviewer (AI/Human) ➔ Analyzer ➔ Coder ➔ ...

정적 컨벤션을 통과한 청정 코드를 대상으로 Reviewer Agent(또는 사람)가 코드 리뷰를 진행합니다.

리뷰 초점: 성능(불필요한 리렌더링), 컴포넌트 가독성, 확장성, 비즈니스 로직의 예외 처리 등.

리뷰 피드백 반영 루프:

Reviewer가 개선이 필요한 부분에 리뷰 코멘트를 남깁니다.

Analyzer가 리뷰 내용을 Task 형태로 정제하여 Coder에게 전달합니다.

Coder가 코드를 수정하면 다시 3단계(Static Gate)를 거쳐 Reviewer에게 재리뷰를 받습니다.

최종 Pass: Reviewer가 모든 코멘트를 Resolve 처리(승인)하면 다음 단계로 진입합니다.

### 5. 동적 테스트 및 TDD 구동 (Dynamic Testing Loop)
Tester ➔ Analyzer ➔ Coder ➔ Tester ➔ ...

리뷰까지 완료된 최종 완성본을 대상으로 Tester가 frontend-tdd-runner 스킬을 구동합니다.

실행 순서: Type Check (npx tsc) ➔ Unit Test ➔ Playwright E2E Test

실패 시: Analyzer가 컴파일 에러나 테스팅 런타임 로그를 분석하여 수정 디렉티브를 생성하고, Coder에게 넘겨 디버깅 코딩을 유도합니다. (자체 max loop 설정으로 무한 루프 방지)

### 6. 최종 완료 및 퍼블리싱 (Goal Completion & Push)
Goal Agent (Ralph) ➔ 시스템 종료

Goal Agent가 모든 테스트(PASS)와 IMPLEMENTATION_SLOT.md에 명시된 완료 조건(모든 스크린 구현, 스토리북 존재 등)이 100% 충족되었는지 최종 검증합니다.

모든 조건이 충족되면 frontend-commit-push 스킬을 호출하여 변경된 코드를 컨벤션에 맞는 메시지로 레포지토리에 안전하게 직접 커밋 및 푸시하고 프로세스를 종료합니다.