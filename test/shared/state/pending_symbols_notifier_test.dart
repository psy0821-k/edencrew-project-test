import 'package:edencrew_assignment_starter/shared/state/pending_symbols_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingSymbolsNotifier', () {
    test(
      'should run the action and clear isPending afterwards when the symbol is not pending',
      () async {
        final notifier = PendingSymbolsNotifier();
        var actionCalled = false;

        await notifier.run('005930', () async {
          actionCalled = true;
        });

        expect(actionCalled, isTrue);
        expect(notifier.isPending('005930'), isFalse);
      },
    );

    test(
      'should mark the symbol as pending while the action is running',
      () async {
        final notifier = PendingSymbolsNotifier();
        bool? pendingDuringAction;

        await notifier.run('005930', () async {
          pendingDuringAction = notifier.isPending('005930');
        });

        expect(pendingDuringAction, isTrue);
      },
    );

    test(
      'should track pending state independently for different symbols',
      () async {
        final notifier = PendingSymbolsNotifier();
        bool? bPendingWhileARunning;

        await notifier.run('005930', () async {
          await notifier.run('000660', () async {
            bPendingWhileARunning = notifier.isPending('000660');
          });
        });

        expect(bPendingWhileARunning, isTrue);
        expect(notifier.isPending('005930'), isFalse);
        expect(notifier.isPending('000660'), isFalse);
      },
    );

    test(
      'should not run the action again when the symbol is already pending',
      () async {
        final notifier = PendingSymbolsNotifier();
        var callCount = 0;

        await notifier.run('005930', () async {
          callCount++;
          await notifier.run('005930', () async {
            callCount++;
          });
        });

        expect(callCount, 1);
      },
    );

    test(
      'should clear isPending even when the action throws',
      () async {
        final notifier = PendingSymbolsNotifier();

        await expectLater(
          notifier.run('005930', () async {
            throw Exception('boom');
          }),
          throwsException,
        );

        expect(notifier.isPending('005930'), isFalse);
      },
    );
  });
}
