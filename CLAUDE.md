# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 성격

이든크루 Flutter 신입 개발자 채용 과제. 국내 주식 관심종목 앱의 화면 3개(관심 목록 / 검색 / 종목 상세)를 Flutter로 구현하는 것이 과제 1, `목표가 알림` 화면 하나를 Lucy Studio로 만드는 것이 과제 2다. 현재 저장소는 `flutter create` 기본 템플릿에 **디자인 토큰과 폰트만 준비된 상태**이며, `lib/` 아래 화면·아키텍처는 전부 새로 설계해야 한다.

- 요구사항 전문: `docs/ASSIGNMENT.md` (화면별 필수/선택 항목, 평가 포인트, 제출 방법)
- Naver 데이터 연동: `docs/NAVER_API.md` (endpoint 4개 + 파싱 규칙)
- Figma 시안은 저장소에 없음 (안내 메일로 전달). 다크 테마 단일 모드, 프레임 기준 `393 × 852`.

## 명령어

```bash
flutter pub get          # 의존성 설치
flutter run              # 실행 — Chrome은 CORS로 Naver endpoint가 막히므로 모바일/에뮬레이터 대상 선택
flutter analyze          # 정적 분석 (제출 필수 통과 조건)
flutter test             # 전체 테스트
flutter test test/widget_test.dart              # 단일 파일
flutter test --plain-name "시작 화면이 다크 테마로 렌더링된다"   # 단일 테스트
```

- 환경: Windows. Flutter SDK `^3.11.5` (Dart 3.11).
- lint: `flutter_lints` 6.x (`analysis_options.yaml`). 커스텀 규칙 없음.

## 아키텍처 · 코드 구조

### 디자인 토큰 (`lib/theme/`, 이미 완성 — 값 수정 금지)

`ThemeExtension` 기반 토큰 시스템. `AppTheme.dark`가 `MaterialApp.theme`에 연결되고, `BuildContext` 확장으로 꺼내 쓴다.

| 파일 | 역할 |
|---|---|
| `app_palette.dart` | 원시 팔레트 (`AppPalette`, Figma Primitives). **화면 코드에서 직접 참조 금지.** |
| `app_colors.dart` | 시맨틱 색상 토큰 (`AppColors`, `ThemeExtension`) |
| `app_dimens.dart` | 간격·반경·크기 토큰 (`AppDimens`, `ThemeExtension`) |
| `app_typography.dart` | `AppTypography.fontFamily` / `regular` / `medium` / `bold` (굵기만, **글자 크기·행간은 토큰 없음** — Figma 텍스트 레이어에서 직접 확인) |
| `app_theme.dart` | `AppTheme.dark` 조립 + `context.colors` / `context.dimens` 확장 |
| `theme.dart` | barrel |

사용 방식:

```dart
Text('삼성전자', style: TextStyle(color: context.colors.textPrimary))
SizedBox(height: context.dimens.space4)
```

**규칙**: 색상 hex를 화면에 직접 쓰거나 `AppPalette`를 화면에서 참조하지 말고 항상 `context.colors.*` 시맨틱 토큰 사용. 토큰 추가는 가능하되 이유를 README 메모에 남길 것. `lib/theme/README.md`에 Figma 변수 ↔ Dart 필드 1:1 대응표가 있다.

도메인 규칙: **등락 색상은 국내 관행 — 상승=빨강(`priceUpText`/`chartLineUp`), 하락=파랑(`priceDownText`/`chartLineDown`), 보합=`priceFlatText`/`priceFlatBg`.** 반대로 구현하지 않도록 주의.

### 앞으로 만들 것 (`lib/` 나머지 — 폴더 구조·상태관리·아키텍처 자유)

`lib/main.dart`의 `StartHereScreen`은 토큰 사용 예시용 임시 화면이므로 교체한다. `EdencrewAssignmentApp`는 유지 가능.

Naver 연동은 요청·파싱·DTO·모델 연결 4가지 모두 직접 구현 (`docs/NAVER_API.md`):

1. 검색 자동완성 `ac.stock.naver.com/ac` — 국내 주식 + 6자리 코드만, canonical id `domestic:{symbol}`
2. 실시간 시세 `polling.finance.naver.com/api/realtime` — **관심종목을 한 요청으로 일괄 조회** (종목별 개별 호출 금지). 등락액 `nv-pcv`, 등락률 `(nv-pcv)/pcv`, 시가총액 `nv×countOfListedStock`
3. 종목 메타데이터 `stock.naver.com/api/securityFe/...` — 종목명·거래소명 (`005930 · 코스피` 표기)
4. 일별 시세 `finance.naver.com/item/sise_day.naver` — **HTML 응답, 인코딩이 UTF-8 아님** (EUC-KR 계열, 디코딩 처리 필요). 한 페이지 10거래일, 기간 탭이 요구하는 만큼만 페이지를 이어 받고 **이미 받은 페이지는 재사용** (평가 비중 높음). `lastPage` 초과 요청 금지.

개발 중에는 응답을 `assets/mock/`에 저장해 파싱부터 맞추는 것을 권장 (mock 파일도 커밋). `pubspec.yaml`에 `assets/mock/` 등록됨.

관심 상태는 관심/검색/상세 세 화면에서 항상 동기화되어야 한다 (전체 필수 요건).

## 커밋

작업 단위로 나눠 커밋 (한 번에 몰아 커밋 금지 — 과제 평가 항목). 커밋 메시지는 한국어.
