import 'stock_meta.dart';
import 'stock_meta_repository.dart';

/// 네트워크 호출 없이 고정된 메타데이터를 반환하는 테스트/개발용 구현체입니다.
class MockStockMetaRepository implements StockMetaRepository {
  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    return StockMeta(symbol: symbol, name: '삼성전자', marketName: '코스피');
  }
}
