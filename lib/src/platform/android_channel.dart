import 'package:flutter/services.dart';

import '../enums/save_directory.dart';

/// Maps [SaveDirectory] enum values to Android's `Environment.DIRECTORY_*`
/// string constants (forwarded via MethodChannel).
const _androidDirectoryMap = <SaveDirectory, String>{
  SaveDirectory.downloads: 'DOWNLOADS',
  SaveDirectory.pictures: 'PICTURES',
  SaveDirectory.movies: 'MOVIES',
  SaveDirectory.dim: 'DCIM',
  SaveDirectory.documents: 'DOCUMENTS',
  SaveDirectory.music: 'MUSIC',
  SaveDirectory.ringtones: 'RINGTONES',
  SaveDirectory.alarms: 'ALARMS',
  SaveDirectory.notifications: 'NOTIFICATIONS',
  // Fallbacks – documented in README
  SaveDirectory.podcasts: 'MUSIC',
  SaveDirectory.audiobooks: 'MUSIC',
  SaveDirectory.screenshots: 'PICTURES',
};

/// Low-level bridge to the Android native plugin via [MethodChannel].
class AndroidChannel {
  static const _channel = MethodChannel('flutter_saver');

  /// Resolves the absolute path for [dir] on the Android device.
  static Future<String?> getDirectoryPath(SaveDirectory dir) async {
    final key = _androidDirectoryMap[dir] ?? 'DOWNLOADS';
    return _channel.invokeMethod<String>('getDirectoryPath', {
      'directory': key,
    });
  }

  /// Saves [bytes] to [directory] with [fileName].
  static Future<String?> saveFile({
    required List<int> bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    final dirKey = _androidDirectoryMap[directory] ?? 'DOWNLOADS';
    return _channel.invokeMethod<String>('saveFile', {
      'bytes': bytes,
      'fileName': fileName,
      'directory': dirKey,
    });
  }
}
