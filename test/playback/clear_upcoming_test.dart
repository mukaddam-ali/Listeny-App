import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/playback/audio_service_playback_service.dart';

MediaItem _item(String id) => MediaItem(id: id, title: id);

void main() {
  test('clear-upcoming removes every displayed item after the current one, and only those', () {
    final items = [_item('a'), _item('b'), _item('c'), _item('d')];

    final cleared = AudioServicePlaybackService.itemsToClearAfter(items, 1);

    expect(cleared.map((i) => i.id).toList(), ['d', 'c']);
  });

  test('clear-upcoming never includes the current track, even at the end of the displayed (shuffled) queue', () {
    final items = [_item('a'), _item('b'), _item('c')];

    final cleared = AudioServicePlaybackService.itemsToClearAfter(items, 2);

    expect(cleared, isEmpty);
  });

  test('clear-upcoming with no current index (-1) clears the whole displayed queue', () {
    final items = [_item('a'), _item('b')];

    final cleared = AudioServicePlaybackService.itemsToClearAfter(items, -1);

    expect(cleared.map((i) => i.id).toList(), ['b', 'a']);
  });
}
