import 'package:flutter_test/flutter_test.dart';
import 'package:listeny/core/copy_title.dart';

void main() {
  test('first copy is numbered 2', () {
    expect(nextCopyTitle('Lesson', ['Lesson']), 'Lesson (2)');
  });

  test('skips numbers already taken', () {
    expect(
      nextCopyTitle('Lesson', ['Lesson', 'Lesson (2)', 'lesson (3)']),
      'Lesson (4)',
    );
  });

  test('copying a copy continues the same sequence', () {
    expect(
      nextCopyTitle('Lesson (2)', ['Lesson', 'Lesson (2)']),
      'Lesson (3)',
    );
  });

  test('stripCopyCounter only removes a trailing (n)', () {
    expect(stripCopyCounter('Lesson (2)'), 'Lesson');
    expect(stripCopyCounter('Lesson 2'), 'Lesson 2');
    expect(stripCopyCounter('Lesson (2) intro'), 'Lesson (2) intro');
  });
}
