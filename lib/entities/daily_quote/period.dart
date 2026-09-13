/// 종목 상세 화면의 기간 탭 4종.
enum Period {
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear;

  /// 이 기간을 표시하는 데 필요한 페이지 수(한 페이지 = 최대 10거래일).
  /// `docs/NAVER_API.md`의 대략치를 그대로 사용한다.
  int get requiredPageCount => switch (this) {
    Period.oneMonth => 2,
    Period.threeMonths => 6,
    Period.sixMonths => 12,
    Period.oneYear => 25,
  };
}
