import 'dart:math';

extension StringExtension on String {
  /// Generates a random file name of a given length.
  ///
  /// Parameters:
  /// - [length]: The length of the random file name.
  ///
  /// Returns a randomly generated file name.
  static String randomFileName(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
