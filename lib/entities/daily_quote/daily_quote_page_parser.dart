import 'package:html/parser.dart' as html_parser;

import '../../shared/error/failure.dart';
import 'daily_quote.dart';
import 'daily_quote_page.dart';

final _lastPageRegExp = RegExp(r'page=(\d+)');

/// `finance.naver.com/item/sise_day.naver`가 반환하는 일별 시세 HTML(UTF-8로
/// 디코딩된 문자열)을 파싱합니다.
///
/// 표의 숫자 순서는 `종가, 전일비, 시가, 고가, 저가, 거래량`이며, 전일비는
/// 사용하지 않습니다(`docs/NAVER_API.md` 참고).
DailyQuotePage parseDailyQuotePage(String html) {
  final document = html_parser.parse(html);

  final lastPageHref = document.querySelector('.pgRR a')?.attributes['href'];
  final lastPageMatch = lastPageHref == null
      ? null
      : _lastPageRegExp.firstMatch(lastPageHref);
  if (lastPageMatch == null) {
    throw const ParsingFailure();
  }
  final lastPage = int.parse(lastPageMatch.group(1)!);

  final rows = document.querySelectorAll('tr[onmouseover]');
  final quotes = rows.map(_parseRow).toList();

  return DailyQuotePage(quotes: quotes, lastPage: lastPage);
}

DailyQuote _parseRow(dynamic row) {
  final dateText = row.querySelector('td[align="center"] span')?.text.trim();
  final numCells = row.querySelectorAll('td.num');

  if (dateText == null || numCells.length < 6) {
    throw const ParsingFailure();
  }

  final date = dateText.replaceAll('.', '');
  final closePrice = _parseNum(numCells[0]);
  // numCells[1] = 전일비 (사용하지 않음)
  final openPrice = _parseNum(numCells[2]);
  final highPrice = _parseNum(numCells[3]);
  final lowPrice = _parseNum(numCells[4]);
  final volume = _parseNum(numCells[5]);

  return DailyQuote(
    date: date,
    closePrice: closePrice,
    openPrice: openPrice,
    highPrice: highPrice,
    lowPrice: lowPrice,
    volume: volume,
  );
}

int _parseNum(dynamic cell) {
  final text = cell.text.trim().replaceAll(',', '');
  final value = int.tryParse(text);
  if (value == null) {
    throw const ParsingFailure();
  }
  return value;
}
