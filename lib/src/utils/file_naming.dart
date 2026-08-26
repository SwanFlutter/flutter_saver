import 'dart:math';

/// Generates a random alphanumeric string of [length] characters.
String _randomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Returns a random file name (without extension).
String generateRandomFileName() => 'file_${_randomString(10)}';
