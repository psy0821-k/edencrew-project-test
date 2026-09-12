/// 관심목록 정렬 기준.
enum SortCriteria {
  /// 현재가 내림차순.
  priceDesc,

  /// 등락률 내림차순.
  changeRateDesc,

  /// 종목명 가나다순(오름차순).
  nameAsc,
}

/// 정렬 칩/바텀시트가 공유하는 한글 라벨.
extension SortCriteriaLabel on SortCriteria {
  String get label => switch (this) {
        SortCriteria.priceDesc => '현재가순',
        SortCriteria.changeRateDesc => '등락률순',
        SortCriteria.nameAsc => '가나다순',
      };
}
