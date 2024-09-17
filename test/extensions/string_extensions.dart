import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_saver/src/tools/extensions/string_extensions.dart';

void main() {
  group(
    'StringExtension',
    () {
      test(
        'randomFileName generates a string of the correct length',
        () {
          const length = 10;
          final result = ''.randomFileName(length);
          expect(result.length, equals(length));
        },
      );

      test(
        'randomFileName generates a string containing only allowed characters',
        () {
          const length = 15;
          final result = ''.randomFileName(length);
          const allowedChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
          final resultChars = result.split('');
          final allAllowed = resultChars.every(
            (char) => allowedChars.contains(char),
          );
          expect(allAllowed, isTrue);
        },
      );

      test(
        'randomFileName generates different strings on multiple calls',
        () {
          const length = 8;
          final results = <String>{};
          const iterations = 100;

          for (var i = 0; i < iterations; i++) {
            final result = ''.randomFileName(length);
            results.add(result);
          }
          expect(results.length, greaterThan(1));
          expect(results.length, greaterThanOrEqualTo(iterations));
        },
      );
    },
  );
}
