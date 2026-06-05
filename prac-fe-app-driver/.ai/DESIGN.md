# Design Spec — prac-fe-app-driver

<!--
  figma-design-workflow 스킬이 이 파일을 파싱합니다.
  각 섹션의 포맷을 유지하며 내용을 채워주세요.
-->

## Design Tokens

<!--
  Toss 디자인 시스템 기반
  참고: https://toss.im / Toss Design System
-->

Primary: #3182F6
Primary-Light: #EBF3FE
Primary-Dark: #1B64DA
Background: #F9FAFB
Surface: #FFFFFF
Surface-Secondary: #F2F4F6
Text-Primary: #191F28
Text-Secondary: #8B95A1
Text-Disabled: #C5CDD7
Text-On-Primary: #FFFFFF
Error: #F04452
Error-Light: #FEECEE
Success: #00B493
Success-Light: #E8FAF6
Warning: #FF9500
Warning-Light: #FFF3E0
Border: #E5E8EB
Divider: #F2F4F6
Map-Overlay: rgba(0,0,0,0.48)
Font-Family: Pretendard
Font-Scale: 12 / 14 / 16 / 18 / 20 / 24 / 28 / 32
Font-Weight: 400 / 500 / 600 / 700
Border-Radius: 8 / 12 / 16 / 20 / 100(pill)
Spacing: 4 / 8 / 12 / 16 / 20 / 24 / 32
Shadow-Card: 0 2px 12px rgba(0,0,0,0.08)
Shadow-Sheet: 0 -4px 20px rgba(0,0,0,0.10)

## Screens

### HomeScreen (대기 화면)
- Route: /home
- Layout: 고정 레이아웃 (상단 상태바 + 중앙 콘텐츠 + 하단 탭바)
- Components:
  - StatusBadge: 운행 가능/불가 토글 — pill shape, Primary/#8B95A1 배경
  - EarningsCard: 오늘 수입 요약 카드 — Surface, Shadow-Card, 24px radius
    - 총 수입 (32px Bold, Text-Primary)
    - 운행 횟수 · 총 운행 거리 (14px, Text-Secondary)
    - "수입 내역 보기" 텍스트 버튼 (14px, Primary)
  - OnlineToggle: 대형 원형 토글 버튼 — 직경 160px, Primary gradient, 가운데 "운행 시작" 텍스트
  - RecentTripList: 최근 운행 2건 미리보기 — FlatList 수평 스크롤
  - BottomTabBar: 홈 / 내역 / 마이페이지
- States: offline | online-waiting | online-matched

### RequestScreen (배차 요청)
- Route: /request (modal overlay — HomeScreen 위에 슬라이드업)
- Layout: BottomSheet (고정 높이 480px, 16px top radius)
- Components:
  - DragHandle: 상단 중앙 4×32px 회색 바
  - RequestTimer: 원형 프로그레스 + 카운트다운 (15초) — 56px, Primary stroke
  - PassengerInfo:
    - 출발지 라벨 (12px Medium, Text-Secondary) + 출발지명 (18px Bold, Text-Primary)
    - ↓ 점선 구분선
    - 목적지 라벨 (12px Medium, Text-Secondary) + 목적지명 (18px Bold, Text-Primary)
  - TripMetaRow: 예상 거리 · 예상 시간 · 예상 요금 — 3열 균등 분할, 각 항목 아이콘+값
  - ActionRow:
    - 거절 버튼: full-width 높이 56px, Surface-Secondary 배경, Text-Secondary 텍스트, 12px radius
    - 수락 버튼: full-width 높이 56px, Primary 배경, Text-On-Primary, 12px radius
- States: countdown | expired | accepting

### NavigationScreen (네비게이션 — 핵심 화면)
- Route: /navigation
- Layout: 지도 전체화면 + 하단 FloatingCard + 상단 FloatingHeader
- Components:
  - MapView: react-native-maps 전체화면, 현재 위치 마커(Primary), 목적지 마커(Error)
  - FloatingHeader (상단 — SafeArea top + 16px):
    - 높이 56px, Surface 배경, Shadow-Card, 20px radius
    - 현재 도로명 (16px SemiBold, Text-Primary) — 좌측
    - 전체 남은 거리 (14px, Text-Secondary) — 우측
  - DirectionBanner (FloatingHeader 아래 8px):
    - 높이 80px, Primary 배경, 20px radius
    - 방향 아이콘 (크게, 32px, white) — 좌측
    - 다음 동작 텍스트 (18px Bold, white) ex: "200m 앞 우회전"
    - 다음 도로명 (14px, rgba(255,255,255,0.8)) — 아래
  - PassengerCard (하단 FloatingCard — SafeArea bottom + 16px):
    - Surface 배경, Shadow-Sheet, 20px top radius
    - padding 20px
    - Row 1: 승객 아바타(40px circle) + 이름(16px SemiBold) + 평점(별 아이콘 + 14px) — 우측 전화 아이콘 버튼
    - Divider (Divider 색상)
    - Row 2: 목적지 아이콘(빨간 점) + 목적지명(16px Medium) + 남은 거리·시간(14px, Text-Secondary)
    - Row 3: ETAChip — "도착 예정 OO:OO" pill (Primary-Light 배경, Primary 텍스트, 12px Medium)
    - Row 4 (하단 액션):
      - 경유지 추가 버튼 (ghost, 44px height, Border 테두리, 12px radius)
      - 운행 종료 버튼 (Error 배경, white 텍스트, 44px height, 12px radius, flex:2)
  - SpeedIndicator: 하단 우측 플로팅 — 원형 56px, Surface, Shadow-Card
    - 현재 속도 숫자 (20px Bold) + "km/h" (10px)
  - RecenterButton: SpeedIndicator 위 — 원형 44px, Surface, Shadow-Card, 위치 아이콘
- States: loading-route | navigating | arrived-pickup | navigating-to-dest | arrived-dest

### ArrivalScreen (승객 픽업 완료)
- Route: /arrival (NavigationScreen 위 BottomSheet overlay)
- Layout: BottomSheet (높이 320px, 20px top radius)
- Components:
  - SuccessIcon: 56px 원형, Success-Light 배경, Success 체크 아이콘
  - Title: "승객을 태웠나요?" (24px Bold, Text-Primary) 중앙정렬
  - Subtitle: 승객 이름 + "님을 태우셨으면 버튼을 눌러주세요" (14px, Text-Secondary)
  - ConfirmButton: "운행 시작" full-width 56px, Primary, 12px radius
  - CancelLink: "아직 탑승하지 않았어요" 텍스트 버튼 (14px, Text-Secondary)
- States: confirming | confirmed

### TripCompleteScreen (운행 완료)
- Route: /trip-complete
- Layout: ScrollView (단일 페이지)
- Components:
  - Header: "운행 완료" (20px Bold) 중앙 + 뒤로가기 불필요(완료 화면이므로 X 버튼)
  - CompletionBadge: 56px 원형 Success-Light + 체크 아이콘
  - FareCard: Surface, Shadow-Card, 16px radius, padding 24px
    - 최종 요금 (32px Bold, Text-Primary) 중앙
    - 거리 / 시간 / 기본요금 / 추가요금 breakdown 리스트 (14px, 좌우 정렬)
  - RouteCard: Surface, Shadow-Card, 16px radius
    - 출발지 → 목적지 아이콘 타임라인
  - RatingRequest: "운행은 어떠셨나요?" 별점 5개 (32px 별 아이콘, Warning 활성)
  - CTAButton: "홈으로 돌아가기" full-width 56px, Primary, 12px radius
- States: loading | success

### HistoryScreen (운행 내역)
- Route: /history
- Layout: FlatList (헤더 고정)
- Components:
  - MonthSelector: 좌우 화살표 + 월 표시 (16px SemiBold) — 수평 중앙
  - MonthlySummary: Surface, Shadow-Card, 16px radius
    - 이번 달 총 수입 (24px Bold) + 운행 횟수 (14px, Text-Secondary)
  - TripItem: 각 운행 기록 행
    - 날짜·시간 (12px, Text-Secondary)
    - 출발→목적지 (14px Medium, Text-Primary)
    - 요금 (16px SemiBold, Text-Primary) — 우측 정렬
    - 하단 Divider
  - EmptyState: 운행 내역 없음 일러스트 + 안내 문구
- States: loading | empty | success

### ProfileScreen (마이페이지)
- Route: /profile
- Layout: ScrollView
- Components:
  - ProfileHeader: Surface, 하단 Shadow
    - 아바타 (72px circle) + 이름 (20px Bold) + 차량 정보 (14px, Text-Secondary)
    - 별점 (별 아이콘 + 16px Bold) + 리뷰 수 (12px, Text-Secondary)
  - SettingsGroup (카드 형태, 16px radius): 각 그룹
    - 차량 정보 관리
    - 알림 설정
    - 공지사항
    - 고객센터
    - 로그아웃 (Error 텍스트)
  - SettingsItem: 아이콘 + 라벨 (16px) + 우측 화살표 — 높이 56px
- States: loading | success

## Component Library

<!--
  Toss 스타일 공통 컴포넌트
-->

Button:
  - primary: Primary 배경 / white 텍스트 / 12px radius / 56px height
  - secondary: Surface-Secondary 배경 / Text-Primary 텍스트 / 12px radius / 56px height
  - ghost: transparent / Border 테두리 / Text-Primary 텍스트 / 12px radius / 44px height
  - danger: Error 배경 / white 텍스트 / 12px radius / 56px height
  - disabled: Surface-Secondary / Text-Disabled / 12px radius

Badge:
  - online: Primary-Light 배경 / Primary 텍스트 / pill / 12px Medium
  - offline: Surface-Secondary / Text-Secondary / pill / 12px Medium
  - eta: Primary-Light / Primary / pill / 12px Medium

Card:
  - default: Surface / Shadow-Card / 16px radius / 20px padding
  - sheet: Surface / Shadow-Sheet / 20px top-radius only
  - floating: Surface / Shadow-Card / 20px radius

Avatar:
  - small: 32px circle
  - medium: 40px circle
  - large: 72px circle

Divider:
  - horizontal: 1px / Divider 색상
  - dot-timeline: 8px dot(Primary or Error) + 세로선(Border)

Icon:
  - 크기: 16 / 20 / 24 / 32
  - 스타일: line (기본) — lucide-react-native 사용

BottomTabBar:
  - 탭 3개: 홈(house) / 내역(receipt) / 마이(person)
  - 활성: Primary 아이콘 + 라벨 / 비활성: Text-Disabled
  - 높이: 56px + SafeArea bottom
  - 배경: Surface / 상단 Border 선

BottomSheet:
  - drag handle: 4×32px / Surface-Secondary / 중앙 / top 12px
  - 배경: Surface
  - 상단 radius: 20px

FloatingCard:
  - position: absolute bottom
  - margin: 16px horizontal
  - radius: 20px
  - Shadow-Sheet
