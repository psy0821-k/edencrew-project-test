import 'dart:async';

import 'package:edencrew_assignment_starter/entities/stock_meta/caching_stock_meta_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// symbol별 응답을 미리 등록해두고, 호출 횟수를 기록하는 fake.
class _RecordingStockMetaRepository implements StockMetaRepository {
  _RecordingStockMetaRepository(
    this._metaBySymbol, {
    this.errorToThrow,
    this.delay,
  });

  final Map<String, StockMeta> _metaBySymbol;
  final Object? errorToThrow;
  final Map<String, int> callCountBySymbol = {};

  /// 지정하면 fetchStockMeta가 이 Future가 완료될 때까지 응답하지 않는다.
  /// (동시에 들어온 여러 호출이 캐시 미스 상태에서 겹치는 상황을 재현하기 위해 사용)
  final Future<void>? delay;

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    callCountBySymbol[symbol] = (callCountBySymbol[symbol] ?? 0) + 1;
    if (delay != null) {
      await delay;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return _metaBySymbol[symbol]!;
  }
}

void main() {
  group('CachingStockMetaRepository', () {
    test(
      '같은 symbol을 두 번 조회하면 delegate의 fetchStockMeta가 1회만 호출되고, '
      '두 번째 호출도 첫 번째와 동일한 StockMeta를 반환한다',
      () async {
        const meta = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
        final delegate = _RecordingStockMetaRepository({'005930': meta});
        final repository = CachingStockMetaRepository(delegate);

        final first = await repository.fetchStockMeta('005930');
        final second = await repository.fetchStockMeta('005930');

        expect(delegate.callCountBySymbol['005930'], 1);
        expect(first, same(second));
      },
    );

    test('서로 다른 symbol을 조회하면 각각 delegate가 호출된다', () async {
      const samsung = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
      const sk = StockMeta(symbol: '000660', name: 'SK하이닉스', marketName: '코스피');
      final delegate = _RecordingStockMetaRepository({
        '005930': samsung,
        '000660': sk,
      });
      final repository = CachingStockMetaRepository(delegate);

      final result1 = await repository.fetchStockMeta('005930');
      final result2 = await repository.fetchStockMeta('000660');

      expect(delegate.callCountBySymbol['005930'], 1);
      expect(delegate.callCountBySymbol['000660'], 1);
      expect(result1.symbol, '005930');
      expect(result2.symbol, '000660');
    });

    test(
      '캐시에 없는 symbol을 조회하면 delegate 호출 후 결과가 캐시에 저장되어, '
      '이어지는 동일 symbol 조회 시 delegate가 다시 호출되지 않는다',
      () async {
        const meta = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
        final delegate = _RecordingStockMetaRepository({'005930': meta});
        final repository = CachingStockMetaRepository(delegate);

        await repository.fetchStockMeta('005930');
        await repository.fetchStockMeta('005930');
        await repository.fetchStockMeta('005930');

        expect(delegate.callCountBySymbol['005930'], 1);
      },
    );

    test(
      'delegate가 예외를 던지면 그 예외가 그대로 전파되고, 실패한 조회는 캐시에 저장되지 않아 '
      '다음 호출에서 재시도된다',
      () async {
        final delegate = _RecordingStockMetaRepository(
          {},
          errorToThrow: Exception('network error'),
        );
        final repository = CachingStockMetaRepository(delegate);

        await expectLater(
          repository.fetchStockMeta('005930'),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          repository.fetchStockMeta('005930'),
          throwsA(isA<Exception>()),
        );

        expect(delegate.callCountBySymbol['005930'], 2);
      },
    );

    test(
      '같은 symbol을 캐시 미스 상태에서 동시에(병렬로) 조회하면 delegate가 1회만 '
      '호출되고, 모든 호출이 동일한 StockMeta를 반환한다',
      () async {
        const meta = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
        final completer = Completer<void>();
        final delegate = _RecordingStockMetaRepository(
          {'005930': meta},
          delay: completer.future,
        );
        final repository = CachingStockMetaRepository(delegate);

        final future1 = repository.fetchStockMeta('005930');
        final future2 = repository.fetchStockMeta('005930');
        final future3 = repository.fetchStockMeta('005930');
        completer.complete();
        final results = await Future.wait([future1, future2, future3]);

        expect(delegate.callCountBySymbol['005930'], 1);
        expect(results[0], same(results[1]));
        expect(results[1], same(results[2]));
      },
    );

    test(
      '캐시 최대 크기를 초과해 새 symbol을 조회하면 가장 오래전에 접근한 항목이 '
      '제거되어 이후 그 symbol을 다시 조회하면 delegate가 재호출된다',
      () async {
        const first = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
        const second = StockMeta(symbol: '000660', name: 'SK하이닉스', marketName: '코스피');
        const third = StockMeta(symbol: '035420', name: 'NAVER', marketName: '코스피');
        final delegate = _RecordingStockMetaRepository({
          '005930': first,
          '000660': second,
          '035420': third,
        });
        final repository = CachingStockMetaRepository(delegate, maxCacheSize: 2);

        await repository.fetchStockMeta('005930');
        await repository.fetchStockMeta('000660');
        await repository.fetchStockMeta('035420');
        await repository.fetchStockMeta('005930');

        expect(delegate.callCountBySymbol['005930'], 2);
        expect(delegate.callCountBySymbol['000660'], 1);
        expect(delegate.callCountBySymbol['035420'], 1);
      },
    );

    test(
      '캐시 최대 크기 이내에서는 오래전에 조회한 symbol도 다시 조회할 때 '
      'delegate가 재호출되지 않는다',
      () async {
        const first = StockMeta(symbol: '005930', name: '삼성전자', marketName: '코스피');
        const second = StockMeta(symbol: '000660', name: 'SK하이닉스', marketName: '코스피');
        final delegate = _RecordingStockMetaRepository({
          '005930': first,
          '000660': second,
        });
        final repository = CachingStockMetaRepository(delegate, maxCacheSize: 2);

        await repository.fetchStockMeta('005930');
        await repository.fetchStockMeta('000660');
        await repository.fetchStockMeta('005930');

        expect(delegate.callCountBySymbol['005930'], 1);
        expect(delegate.callCountBySymbol['000660'], 1);
      },
    );
  });
}
