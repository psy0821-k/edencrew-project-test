# Issue #46 — 검색 화면 디자인 다듬기: 별 아이콘 색상 / 결과 리스트 / 토스트 UI

> 이슈 하나에 우선순위가 다른 작업 3개(별 아이콘 색상 → 결과 리스트 디자인 → 토스트 UI)가 묶여 있다.
> 이 문서는 우선순위 1(별 아이콘 fill 색상)의 시그니처/시나리오만 우선 기록한다. 2, 3번은 착수 시 이 문서에 이어서 추가한다.

## 우선순위 1 — 즐겨찾기(별 아이콘) fill 색상 수정

### 시그니처

`lib/features/search-list/search_result_row.dart`의 별 아이콘 `SvgPicture.asset` 호출에 `colorFilter`를 추가한다 (새 파일/함수 없음, 기존 위젯 내부 수정).

```dart
SvgPicture.asset(
  isFavorite
      ? 'assets/icons/ico_star_filled.svg'
      : 'assets/icons/ico_star.svg',
  width: _starIconSize,
  height: _starIconSize,
  colorFilter: ColorFilter.mode(
    isFavorite ? colors.favoriteActive : colors.favoriteInactive,
    BlendMode.srcIn,
  ),
),
```

- `assets/icons/ico_star.svg`/`ico_star_filled.svg`는 동일한 별 path 하나로 구성되어 있고 `fill`/`stroke` 색만 다름(SVG 자체는 fill=stroke 색이 같은 구조) — `colorFilter`(`BlendMode.srcIn`) 하나로 전체 색을 시맨틱 토큰에 맞게 통일 가능, 새 asset이나 CustomPainter 불필요.
- `context.colors.favoriteActive`/`favoriteInactive` 시맨틱 토큰만 사용, `AppPalette`/hex 직접 참조 없음.

## 테스트 시나리오

### `SearchResultRow` (별 아이콘 색상)

- [정상] 관심등록된 종목의 별 아이콘을 렌더링하면 `colorFilter`가 `context.colors.favoriteActive`로 설정되어야 한다
- [정상] 관심등록되지 않은 종목의 별 아이콘을 렌더링하면 `colorFilter`가 `context.colors.favoriteInactive`로 설정되어야 한다
- [경계] 관심 상태가 토글되면(등록↔해제) 별 아이콘의 `colorFilter` 색상도 즉시 바뀌어야 한다

## AC 커버리지 대조 (우선순위 1 관련 AC만)

| GitHub #46 AC | 커버 시나리오 |
|---|---|
| 관심등록된 별 아이콘 fill 색상이 `context.colors.favoriteActive`와 일치 | [정상] 관심등록 시 `favoriteActive` |
| 관심등록되지 않은 별 아이콘이 fill 없이 테두리만 `context.colors.favoriteInactive` | [정상] 관심등록 안 됨 시 `favoriteInactive` |

나머지 AC(검색 결과 리스트 디자인, 토스트 UI, flutter analyze/회귀)는 우선순위 2·3 작업 완료 후 최종 확인한다.
