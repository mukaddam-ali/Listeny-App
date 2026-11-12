import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/features/import/video_import_flow.dart';

void main() {
  test('real names are kept, separators become spaces', () {
    expect(suggestedTrackName('Time_Management-Basics'), 'Time Management Basics');
  });

  test('numbers and camera-style names give no suggestion', () {
    expect(suggestedTrackName('1106'), '');
    expect(suggestedTrackName('1000012345'), '');
    expect(suggestedTrackName('VID_20261106_101500'), '');
    expect(suggestedTrackName('IMG-2026-11-06'), '');
  });
}
