# Issue #18 — [Phase2-3] 관심목록 정렬 (SortCriteria + comparator)

## 시그니처

### `lib/features/watchlist-sort/sort_criteria.dart`

```dart
/// 관심목록 정렬 기준.
enum SortCriteria {
  /// 현재가 내림차순.
  priceDesc,

  /// 등락률 내림차순.
  changeRateDesc,

  /// 종목명 가나다순(오름차순).
  nameAsc,
}
```

### `lib/features/watchlist-sort/watchlist_comparator.dart`

```dart
import '../../entities/watchlist/watchlist_item.dart';
import 'sort_criteria.dart';

/// [items]를 [criteria] 기준으로 정렬한 새 리스트를 반환하는 순수 함수.
///
/// - `priceDesc`/`changeRateDesc`: `quote == null`인 항목은 항상 결과의 맨 뒤로 보낸다.
/// - `nameAsc`: `stockMeta.name`은 항상 값이 존재하므로 null 처리가 필요 없다.
/// - `items`를 변경하지 않고 정렬된 새 리스트를 반환한다(원본 비파괴).
List<WatchlistItem> sortWatchlistItems(
  List<WatchlistItem> items,
  SortCriteria criteria,
) {
  final sorted = List<WatchlistItem>.of(items);
  switch (criteria) {
    case SortCriteria.priceDesc:
      sorted.sort(_byPriceDesc);
    case SortCriteria.changeRateDesc:
      sorted.sort(_byChangeRateDesc);
    case SortCriteria.nameAsc:
      sorted.sort(_byNameAsc);
  }
  return sorted;
}

int _byPriceDesc(WatchlistItem a, WatchlistItem b) {
  if (a.quote == null && b.quote == null) return 0;
  if (a.quote == null) return 1;
  if (b.quote == null) return -1;
  return b.quote!.currentPrice.compareTo(a.quote!.currentPrice);
}

int _byChangeRateDesc(WatchlistItem a, WatchlistItem b) {
  if (a.quote == null && b.quote == null) return 0;
  if (a.quote == null) return 1;
  if (b.quote == null) return -1;
  return b.quote!.changeRate.compareTo(a.quote!.changeRate);
}

int _byNameAsc(WatchlistItem a, WatchlistItem b) {
  return a.stockMeta.name.compareTo(b.stockMeta.name);
}
```

### `lib/features/watchlist-sort/watchlist_sort_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sort_criteria.dart';

/// 관심 화면에서 현재 선택된 정렬 기준. 기본값은 현재가순(`priceDesc`).
///
/// PRD/스펙에 기본값이 명시되어 있지 않아, 관심 화면 첫 진입 시 가장 자연스러운
/// 기준(보유 관심종목의 자산가치를 바로 파악할 수 있는 현재가순)으로 자율 판단했다.
final watchlistSortCriteriaProvider = StateProvider<SortCriteria>(
  (ref) => SortCriteria.priceDesc,
);
```

### 에러 케이스

- 없음. `sortWatchlistItems`는 순수 함수로 예외를 던지지 않으며(빈 리스트도 빈 리스트를 반환),
  `watchlistSortCriteriaProvider`는 단순 `StateProvider`로 값 대입 외 실패 조건이 없다.

## 자율 판단 근거

- **등락률 계산**: `lib/entities/quote/quote.dart`에 이미 `changeRate` getter가 정의되어 있다
  (`(currentPrice - previousClose) / previousClose`, PRD/`docs/NAVER_API.md` 계산식과 동일).
  직접 재계산하지 않고 `quote.changeRate`를 그대로 사용한다 — DRY 원칙, 계산식 중복 방지.
- **가나다순 오름차순에 별도 Collator가 필요한지**: 불필요하다고 판단.
  - 근거: 실제로 `dart run`으로 `['다음카카오', '가나다전자', '나이키', '삼성전자'].sort()`를
    검증한 결과 `[가나다전자, 나이키, 다음카카오, 삼성전자]`로 정상적인 가나다순이 나왔다.
  - 이유: 한글 완성형(가~힣, U+AC00~U+D7A3) 코드포인트는 초성→중성→종성 순서로 유니코드에
    할당되어 있어, 코드포인트(=UTF-16 코드유닛) 순서가 가나다 사전순과 일치한다. Dart의 기본
    `String.compareTo`는 UTF-16 코드유닛 비교이므로 별도 `Collator`/로케일 처리 없이
    `a.stockMeta.name.compareTo(b.stockMeta.name)`만으로 가나다순이 보장된다.
  - 범위 제한: 이 판단은 완성형 한글 종목명에 한정된다. 자모 분리형(호환 자모, U+3131~)이나
    영문/숫자 혼합 종목명의 사전편찬적(locale-aware) 정렬은 이슈 범위 밖(YAGNI) — 국내 상장
    종목명은 완성형 한글 또는 영문 표기이므로 실무상 문제가 되지 않는다.
- **정렬 안정성**: `List.sort`는 Dart에서 안정 정렬을 보장하지 않으므로(퀵소트 계열), 동일 값
  (예: 현재가가 같은 두 종목)의 상대 순서는 시나리오에서 검증하지 않는다 — AC/PRD 모두 동순위
  타이브레이크 규칙을 요구하지 않는다(가장 좁은 해석).
- **`quote == null` 두 항목 간 순서**: PRD/AC는 "맨 뒤에 위치"만 요구하고 null 항목끼리의
  상대 순서는 명시하지 않는다. comparator는 `return 0`(순서 유지, 입력 순서에 의존)으로 처리했고,
  테스트도 "두 null 항목이 결과의 뒤쪽 두 자리를 모두 차지하는지"만 검증한다(상호 순서는
  비검증 — 가장 좁은 해석).
- **원본 리스트 비파괴**: 기존 `watchlist_item.dart`/`watchlist_providers.dart` 등 엔티티 계층이
  불변성을 지향하는 스타일(모든 필드 `final`, `const` 생성자)과 일관되게, `sortWatchlistItems`도
  입력 `items`를 직접 정렬하지 않고 복사본을 정렬해 반환한다.

## 테스트 시나리오

### `sortWatchlistItems`

- [정상] 시세가 모두 있는 `WatchlistItem` 목록을 `SortCriteria.priceDesc`로 정렬하면 현재가
  내림차순으로 정렬되어야 한다 (AC 1)
- [정상] 시세가 모두 있는 `WatchlistItem` 목록을 `SortCriteria.changeRateDesc`로 정렬하면 등락률
  내림차순으로 정렬되어야 한다 (AC 2)
- [정상] 종목명이 서로 다른 `WatchlistItem` 목록을 `SortCriteria.nameAsc`로 정렬하면 가나다순으로
  정렬되어야 한다 (AC 3)
- [경계] 일부 항목은 `quote`가 있고 일부는 `null`인 목록을 `SortCriteria.priceDesc`로 정렬하면
  `quote == null`인 항목이 모두 결과의 맨 뒤에 위치해야 한다 (AC 4)
- [경계] 일부 항목은 `quote`가 있고 일부는 `null`인 목록을 `SortCriteria.changeRateDesc`로
  정렬하면 `quote == null`인 항목이 모두 결과의 맨 뒤에 위치해야 한다 (AC 4)
- [경계] 모든 항목의 `quote`가 `null`인 목록을 `SortCriteria.priceDesc`로 정렬하면 예외 없이
  원래 순서(상대 순서 유지)를 그대로 반환해야 한다
- [경계] 빈 리스트(`[]`)를 어떤 `SortCriteria`로 정렬해도 빈 리스트를 반환해야 한다
- [경계] 항목이 1개뿐인 리스트를 정렬하면 그 항목 하나만 담긴 리스트를 그대로 반환해야 한다
- [정상] `sortWatchlistItems` 호출 후에도 인자로 넘긴 원본 리스트의 순서는 변경되지 않아야 한다
  (원본 비파괴 확인)

### `watchlistSortCriteriaProvider`

- [정상] `watchlistSortCriteriaProvider`를 초기 상태로 읽으면 `SortCriteria.priceDesc`를
  반환해야 한다
- [정상] `watchlistSortCriteriaProvider`의 상태를 `SortCriteria.nameAsc`로 변경하면, 이후 읽었을
  때 즉시 `SortCriteria.nameAsc`를 반환해야 한다 (AC 5)
- [정상] `watchlistSortCriteriaProvider`를 구독 중일 때 상태를 변경하면, 리스너가 별도 재구독
  없이 변경된 값으로 자동 갱신되어야 한다 (AC 5 보강 — "즉시 갱신" 요건의 구독자 관점 검증)

## AC 커버리지

| AC | 커버 시나리오 |
|---|---|
| 1. `priceDesc` → 현재가 내림차순 | `sortWatchlistItems` 정상 시나리오 1번째 |
| 2. `changeRateDesc` → 등락률 내림차순 | `sortWatchlistItems` 정상 시나리오 2번째 |
| 3. `nameAsc` → 가나다순 | `sortWatchlistItems` 정상 시나리오 3번째 |
| 4. `quote == null` 항목은 항상 맨 뒤 | `sortWatchlistItems` 경계 시나리오 1, 2번째(`priceDesc`/`changeRateDesc` 각각) |
| 5. `watchlistSortCriteriaProvider` 변경 시 즉시 갱신 | `watchlistSortCriteriaProvider` 정상 시나리오 2, 3번째(값 조회 + 구독자 자동 갱신) |

5/5 AC 모두 최소 1개 이상의 시나리오로 커버됨. 추가로 경계 케이스(전원 null, 빈 리스트, 단일
항목, 원본 비파괴)를 자율 보강해 견고성을 높였다.
