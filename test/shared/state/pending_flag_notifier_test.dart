import 'package:edencrew_assignment_starter/shared/state/pending_flag_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingFlagNotifier', () {
    test(
      'should run the action and clear isPending afterwards when not pending',
      () async {
        final notifier = PendingFlagNotifier();
        var actionCalled = false;

        await notifier.run(() async {
          actionCalled = true;
        });

        expect(actionCalled, isTrue);
        expect(notifier.isPending, isFalse);
      },
    );

    test(
      'should not run the action again when it is already pending',
      () async {
        final notifier = PendingFlagNotifier();
        var callCount = 0;

        await notifier.run(() async {
          callCount++;
          await notifier.run(() async {
            callCount++;
          });
        });

        expect(callCount, 1);
      },
    );

    test(
      'should clear isPending even when the action throws',
      () async {
        final notifier = PendingFlagNotifier();

        await expectLater(
          notifier.run(() async {
            throw Exception('boom');
          }),
          throwsException,
        );

        expect(notifier.isPending, isFalse);
      },
    );
  });
}
