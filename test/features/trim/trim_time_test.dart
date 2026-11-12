import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/features/trim/trim_time.dart';

void main() {
  group('parseTrimTime', () {
    test('plain seconds, with and without decimals', () {
      expect(parseTrimTime('13'), const Duration(seconds: 13));
      expect(parseTrimTime('13.5'), const Duration(milliseconds: 13500));
      expect(parseTrimTime('.25'), const Duration(milliseconds: 250));
      expect(parseTrimTime('0.001'), const Duration(milliseconds: 1));
    });

    test('minutes and hours', () {
      expect(parseTrimTime('1:05'), const Duration(minutes: 1, seconds: 5));
      expect(
        parseTrimTime('1:05.5'),
        const Duration(minutes: 1, seconds: 5, milliseconds: 500),
      );
      expect(
        parseTrimTime('1:02:03.25'),
        const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 250),
      );
    });

    test('comma and Arabic digits/separator are accepted', () {
      expect(parseTrimTime('13,5'), const Duration(milliseconds: 13500));
      expect(parseTrimTime('١٣٫٥'), const Duration(milliseconds: 13500));
      expect(parseTrimTime('۱:۰۵'), const Duration(minutes: 1, seconds: 5));
    });

    test('rejects junk', () {
      for (final bad in ['', '  ', 'abc', '1:2:3:4', '-5', '1.2.3', '1::2']) {
        expect(parseTrimTime(bad), isNull, reason: bad);
      }
      expect(parseTrimTime('400000'), isNull); // absurdly long
    });
  });

  group('formatTrimTime', () {
    test('omits zero milliseconds and trailing zeros', () {
      expect(formatTrimTime(const Duration(seconds: 13)), '0:13');
      expect(formatTrimTime(const Duration(milliseconds: 13500)), '0:13.5');
      expect(formatTrimTime(const Duration(milliseconds: 13050)), '0:13.05');
      expect(formatTrimTime(const Duration(minutes: 3, seconds: 7)), '3:07');
    });

    test('shows hours when needed and round-trips', () {
      const d = Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 250);
      expect(formatTrimTime(d), '1:02:03.25');
      expect(parseTrimTime(formatTrimTime(d)), d);
    });
  });
}
