import 'package:edencrew_assignment_starter/features/watchlist-sort/sort_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SortCriteria', () {
    test('should have priceDesc, changeRateDesc, nameAsc as its values', () {
      expect(SortCriteria.values, [
        SortCriteria.priceDesc,
        SortCriteria.changeRateDesc,
        SortCriteria.nameAsc,
      ]);
    });
  });
}
