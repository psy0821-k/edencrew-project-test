# project-foundation — 초기 아이디어

## 무엇을

이든크루 Flutter 과제(관심종목 앱)를 본격 구현하기 전에 필요한 **프로젝트 아키텍처 뼈대**를 세운다. ROADMAP.md의 Phase 0에 해당한다.

## 포함 범위 (ROADMAP Phase 0)

- 상태관리 라이브러리 선택 및 도입
- 폴더 구조 설계 — **FSD(Feature-Sliced Design) 기반, 사용자/기능 중심 구조**
- `lib/main.dart`의 `StartHereScreen` 제거, 라우팅 뼈대 구성
  - 관심 ↔ 검색 하단 탭
  - 상세 화면 push
- HTTP 클라이언트 준비
- mock(`assets/mock/`) ↔ network 데이터 소스 전환 구조
- `flutter analyze` 클린 유지

## 제약 / 전제

- Flutter SDK `^3.11.5` (Dart 3.11), Windows 개발 환경
- 다크 테마 단일 모드, 디자인 토큰(`lib/theme/`)은 이미 완성 — 수정 금지
- Chrome 실행 불가 (Naver endpoint CORS) → 모바일/에뮬레이터 대상
- 불필요한 라이브러리 추가 지양 (CLAUDE.md 규칙)
- 기술 선택은 "왜 그 선택을 했는지" 설명 가능해야 함 (과제 평가 항목)

## 확정 필요 (인터뷰 대상)

- 상태관리: 무엇을? (Provider / Riverpod / Bloc / 기타)
- FSD 레이어를 Flutter/Dart에 어떻게 매핑할지
- 라우팅: 패키지(go_router 등) vs Navigator 1.0
- HTTP: 패키지(dio / http) 선택
- mock/network 전환: 컴파일 타임(`--dart-define`) vs 런타임 토글
- 이 Phase의 "완료" 판정 기준
