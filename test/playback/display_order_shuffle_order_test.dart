import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/playback/listeny_audio_handler.dart';

void main() {
  group('DisplayOrderShuffleOrder.insert', () {
    test('play-next at the last shuffled position appends at the end of the displayed order without throwing', () {
      final order = DisplayOrderShuffleOrder();
      order.insert(
        0,
        3,
      ); // seed 3 items (random placement, order irrelevant here)
      expect(order.indices.length, 3);

      // "Play next" while the current track is the last displayed item asks
      // to insert at displayLength (one past the end) — this used to be an
      // out-of-range shuffleIndices[] lookup that threw.
      order.pendingDisplayPosition = order.indices.length;
      order.insert(3, 1); // value 3 = the new item's underlying index

      expect(order.indices.last, 3);
      expect(order.indices.length, 4);
    });

    test('inserts at the exact requested displayed position instead of a random one', () {
      final order = DisplayOrderShuffleOrder();
      order.indices.addAll([2, 0, 1]);

      order.pendingDisplayPosition = 1;
      order.insert(3, 1);

      expect(order.indices, [2, 3, 0, 1]);
    });

    test('reorder (remove then insert at a requested position) lands exactly where asked', () {
      final order = DisplayOrderShuffleOrder();
      order.indices.addAll([2, 0, 1]); // displayed order: item2, item0, item1

      // Move the item currently at displayed position 0 (raw value 2) to
      // displayed position 2 (the end) — mirrors what just_audio's
      // ConcatenatingAudioSource.move() does internally: remove, then insert.
      order.removeRange(2, 3);
      order.pendingDisplayPosition = 2;
      order.insert(2, 1);

      expect(order.indices, [0, 1, 2]);
    });

    test(
      'falls back to a valid (non-throwing) position when none was requested',
      () {
        final order = DisplayOrderShuffleOrder();
        order.indices.addAll([0, 1, 2]);

        order.insert(3, 1); // pendingDisplayPosition left null

        expect(order.indices.length, 4);
        expect(order.indices, containsAll([0, 1, 2, 3]));
      },
    );

    test('consumes pendingDisplayPosition so it never leaks into the next unrelated insert', () {
      final order = DisplayOrderShuffleOrder();
      order.indices.addAll([0]);

      order.pendingDisplayPosition = 0;
      order.insert(1, 1);
      expect(order.pendingDisplayPosition, isNull);
    });
  });

  group('DisplayOrderShuffleOrder.removeRange', () {
    test('removing an item in shuffled mode drops it and shifts later raw indices down, leaving the rest in relative order', () {
      final order = DisplayOrderShuffleOrder();
      order.indices.addAll([2, 0, 3, 1]); // displayed order values

      order.removeRange(2, 3); // remove the item whose raw index is 2

      expect(order.indices, [0, 2, 1]);
    });
  });
}
