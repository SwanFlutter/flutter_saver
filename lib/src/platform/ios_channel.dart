import 'package:flutter/services.dart';

import '../enums/save_directory.dart';

/// Maps [SaveDirectory] to directory keys understood by the iOS Swift plugin.
const _iosDirectoryMap = <SaveDirectory, String>{
  SaveDirectory.downloads: 'downloads',
  SaveDirectory.pictures: 'pictures',
  SaveDirectory.movies: 'movies',
  SaveDirectory.dim: 'dcim',
  SaveDirectory.documents: 'documents',
  SaveDirectory.music: 'music',
  SaveDirectory.podcasts: 'podcasts',
  SaveDirectory.ringtones: 'ringtones',
  SaveDirectory.alarms: 'alarms',
  SaveDirectory.notifications: 'notifications',
  SaveDirectory.screenshots: 'screenshots',
  SaveDirectory.audiobooks: 'audiobooks',
};

/// Low-level bridge to the iOS native plugin via [MethodChannel].
class IosChannel {
  static const _channel = MethodChannel('flutter_saver');

  /// Saves [bytes] to the iOS sandbox sub-folder that corresponds to [directory].
  static Future<String?> saveFile({
    required List<int> bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    final dirKey = _iosDirectoryMap[directory] ?? 'downloads';
    return _channel.invokeMethod<String>('saveFile', {
      'bytes': bytes,
      'fileName': fileName,
      'directory': dirKey,
    });
  }
}
