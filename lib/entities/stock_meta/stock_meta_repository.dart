import 'stock_meta.dart';

/// 종목 메타데이터를 조회하는 방법을 추상화합니다.
///
/// 구현체는 [MockStockMetaRepository](실제 네트워크 없이 고정 데이터 반환)와
/// [NetworkStockMetaRepository](Naver 종목 메타데이터 API 호출) 두 가지가 있으며,
/// `dataSourceModeProvider`가 어떤 구현체를 쓸지 결정합니다.
abstract interface class StockMetaRepository {
  Future<StockMeta> fetchStockMeta(String symbol);
}
