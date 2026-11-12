import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/playback/play_record_gate.dart';

void main() {
  group('PlayRecordGate (recordPlay must not fire for a metadata-only '
      'refresh of the same track id)', () {
    test('a genuinely new track id should record a play', () {
      final gate = PlayRecordGate();
      expect(gate.onCurrentTrackChanged('a'), 'a');
    });

    test('a metadata-only refresh of the SAME track id (e.g. album rename '
        "pushing an updated currentTrack) must NOT record another play — "
        'this is the exact bug: refreshTrackMetadata pushes a new '
        'currentTrack value with an unchanged id, and that must not look '
        'like a new play', () {
      final gate = PlayRecordGate();
      expect(gate.onCurrentTrackChanged('a'), 'a');
      // Same id again, simulating a metadata-only refresh.
      expect(gate.onCurrentTrackChanged('a'), isNull);
      expect(gate.onCurrentTrackChanged('a'), isNull);
    });

    test('a REAL track change (different id) still records a play normally, '
        'even right after a metadata-only refresh of the previous track', () {
      final gate = PlayRecordGate();
      expect(gate.onCurrentTrackChanged('a'), 'a');
      expect(gate.onCurrentTrackChanged('a'), isNull); // metadata refresh
      expect(gate.onCurrentTrackChanged('b'), 'b'); // real transition
    });

    test('null (playback stopped/cleared) resets memory, so replaying the '
        'same track id afterwards is counted as a genuine new play', () {
      final gate = PlayRecordGate();
      expect(gate.onCurrentTrackChanged('a'), 'a');
      expect(gate.onCurrentTrackChanged(null), isNull);
      expect(gate.onCurrentTrackChanged('a'), 'a');
    });

    test('null with nothing recorded yet is a no-op', () {
      final gate = PlayRecordGate();
      expect(gate.onCurrentTrackChanged(null), isNull);
    });

    test('alternating between two tracks records each transition once', () {
      final gate = PlayRecordGate();
      expect(gate.onCurrentTrackChanged('a'), 'a');
      expect(gate.onCurrentTrackChanged('b'), 'b');
      expect(gate.onCurrentTrackChanged('a'), 'a');
      expect(gate.onCurrentTrackChanged('a'), isNull); // refresh, not a play
    });
  });
}
