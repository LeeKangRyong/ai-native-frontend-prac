# Implementation Slot — Phase C (prac-fe-app-user)

<!--
  하네스/goal 시스템 연결 지점 정의.
  추후 하네스 또는 goal 추가 시 아래 스펙을 참고하여 연결하세요.
-->

## 진입 조건

- `figma-design-workflow` 스킬 완료
- 사용자 Figma 승인 ("구현 시작해줘" / "코드 작성해줘" / "ok 시작해")

## Input — 하네스/goal에 전달할 컨텍스트

| 파일 | 역할 |
|---|---|
| `.ai/API.md` | 데이터 구조, 엔드포인트 → TypeScript 타입 정의 기반 |
| `.ai/CONVENTIONS.md` | 폴더 구조, 네이밍 규칙 → 코드 생성 규칙 |
| `.ai/DESIGN.md` | 화면 목록, 컴포넌트 스펙 → 구현 범위 정의 |
| Figma 링크 | `figma-design-workflow`가 생성한 Figma URL |

## Goal Criteria — 완료 조건

하네스/goal이 아래 조건을 모두 충족해야 Phase C 완료로 간주합니다.

- [ ] `DESIGN.md`의 모든 Screen 구현 (`src/screens/`)
- [ ] `CONVENTIONS.md`의 폴더 구조 / 네이밍 규칙 준수
- [ ] 각 컴포넌트마다 `.stories.tsx` 존재 (`storybook-writer` 호출)
- [ ] `npx tsc --noEmit` 통과
- [ ] `npm test -- --watchAll=false` 통과

## 반응형 필수 세팅 (Phase C 구현 시 준수)

### 설계 기준
- Figma 디자인 기준 프레임: **390×844 (iPhone 14)**
- Safe Area: top **59px** / bottom **34px** (Figma 오버레이 컴포넌트 기준)
- 실제 기기별 Safe Area는 `react-native-safe-area-context`로 런타임 처리

### 필수 패키지
```
react-native-safe-area-context   — Safe Area 런타임 처리
```

### 앱 진입점 (App.tsx 또는 최상위 root)
```tsx
import { SafeAreaProvider } from 'react-native-safe-area-context';

export default function App() {
  return (
    <SafeAreaProvider>
      {/* navigation / screens */}
    </SafeAreaProvider>
  );
}
```

### 화면 컴포넌트 패턴
```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useWindowDimensions } from 'react-native';
import { Platform } from 'react-native';

export function SomeScreen() {
  const insets = useSafeAreaInsets();
  const { width, height } = useWindowDimensions();

  return (
    <View style={{ paddingTop: insets.top, paddingBottom: insets.bottom }}>
      {/* content */}
    </View>
  );
}
```

### Platform 분기 패턴 (Android 네비게이션 등 OS별 차이 필요 시)
```tsx
const style = Platform.select({
  ios: { /* iOS 전용 */ },
  android: { /* Android 전용 */ },
});
```

### Goal Criteria 추가 조건
- [ ] `SafeAreaProvider`가 앱 루트에 존재
- [ ] 각 Screen에서 `useSafeAreaInsets()` 또는 `SafeAreaView` 사용
- [ ] 하드코딩된 padding top/bottom 값 없음 (Safe Area 값은 런타임으로만 처리)

## 코드 생성 순서 (권장)

```
① src/types/       — API.md 기반 TypeScript 타입
② src/components/  — DESIGN.md Component Library 기반
③ src/screens/     — DESIGN.md Screens 기반
④ src/hooks/       — 데이터 페칭 / 상태 관리
⑤ src/navigation/  — 화면 간 네비게이션 연결
```

## 스킬 체인

```
[하네스/goal]
  └─ 컴포넌트 생성 시마다 → storybook-writer 호출
  └─ Phase C 완료 후 → frontend-tdd-runner (validate-only)
  └─ tdd-runner 통과 후 → frontend-commit-push
```
