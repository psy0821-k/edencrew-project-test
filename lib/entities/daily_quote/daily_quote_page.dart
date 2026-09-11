import 'daily_quote.dart';

/// 일별 시세 한 페이지(최대 10거래일)의 파싱 결과입니다.
class DailyQuotePage {
  const DailyQuotePage({required this.quotes, required this.lastPage});

  /// 날짜 역순(최신순)으로 정렬된 일별 시세 목록.
  final List<DailyQuote> quotes;

  /// 응답 HTML의 "맨뒤" 링크에서 추출한 마지막 페이지 번호.
  final int lastPage;
}
