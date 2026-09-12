import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sort_criteria.dart';

/// 관심 화면에서 현재 선택된 정렬 기준. 기본값은 가나다순(`nameAsc`).
final watchlistSortCriteriaProvider = StateProvider<SortCriteria>(
  (ref) => SortCriteria.nameAsc,
);
