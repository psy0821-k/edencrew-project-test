/// 하루 단위 시세(일별 시세)입니다.
class DailyQuote {
  const DailyQuote({
    required this.date,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
  });

  /// `yyyyMMdd` 형태의 날짜. 예: `20260911`
  ///
  /// 화면에는 `MM.dd`(연도 없이) 표시하지만, 내부 저장은 연도를 포함한
  /// `yyyyMMdd`를 유지합니다 — 연도를 지우면 연말/연초 경계에서 정렬이
  /// 꼬이고 여러 해에 걸친 데이터에서 날짜가 중복될 수 있기 때문입니다.
  /// 화면 표시는 `DateFormatter.internalToDisplay`로 변환해서 씁니다.
  final String date;

  final int closePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int volume;
}
