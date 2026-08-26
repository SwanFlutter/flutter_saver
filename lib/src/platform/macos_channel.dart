import 'package:flutter/services.dart';

import '../enums/save_directory.dart';

/// Maps [SaveDirectory] to directory keys understood by the macOS Swift plugin.
///
/// macOS supports only a subset of the directories (real system folders).
/// Others fall back to [SaveDirectory.downloads].
const _macosDirectoryMap = <SaveDirectory, String>{
  SaveDirectory.downloads: 'downloads',
  SaveDirectory.pictures: 'pictures',
  SaveDirectory.movies: 'movies',
  SaveDirectory.dim: 'pictures', // fallback
  SaveDirectory.documents: 'documents',
  SaveDirectory.music: 'music',
  // All others fall back to downloads
};

/// Low-level bridge to the macOS native plugin via [MethodChannel].
class MacosChannel {
  static const _channel = MethodChannel('flutter_saver');

  /// Saves [bytes] on macOS into the folder that corresponds to [directory].
  static Future<String?> saveFile({
    required List<int> bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    final dirKey = _macosDirectoryMap[directory] ?? 'downloads';
    return _channel.invokeMethod<String>('saveFile', {
      'bytes': bytes,
      'fileName': fileName,
      'directory': dirKey,
    });
  }
}
