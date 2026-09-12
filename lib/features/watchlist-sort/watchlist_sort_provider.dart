import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sort_criteria.dart';

/// 관심 화면에서 현재 선택된 정렬 기준. 기본값은 현재가순(`priceDesc`).
///
/// PRD/스펙에 기본값이 명시되어 있지 않아, 관심 화면 첫 진입 시 가장 자연스러운
/// 기준(보유 관심종목의 자산가치를 바로 파악할 수 있는 현재가순)으로 자율 판단했다.
final watchlistSortCriteriaProvider = StateProvider<SortCriteria>(
  (ref) => SortCriteria.priceDesc,
);
