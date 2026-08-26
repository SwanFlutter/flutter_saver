import 'package:flutter/services.dart';

import '../enums/save_directory.dart';
import '../models/save_result.dart';

/// Maps [SaveDirectory] to XDG directory keys understood by the Linux plugin.
const _linuxDirectoryMap = <SaveDirectory, String>{
  SaveDirectory.downloads: 'downloads',
  SaveDirectory.pictures: 'pictures',
  SaveDirectory.movies: 'movies',
  SaveDirectory.dim: 'downloads', // fallback — no XDG DCIM
  SaveDirectory.documents: 'documents',
  SaveDirectory.music: 'music',
  SaveDirectory.podcasts: 'music', // fallback
  SaveDirectory.ringtones: 'music', // fallback
  SaveDirectory.alarms: 'downloads', // fallback
  SaveDirectory.notifications: 'downloads', // fallback
  SaveDirectory.screenshots: 'pictures', // fallback
  SaveDirectory.audiobooks: 'music', // fallback
};

/// Linux implementation of flutter_saver.
///
/// Delegates to the native C plugin via MethodChannel, which uses
/// GLib / XDG user-dirs to resolve standard directories and
/// g_file_set_contents for atomic file writing.
class LinuxSaver {
  static const _channel = MethodChannel('flutter_saver');

  static Future<SaveResult> saveFile({
    required Uint8List bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    final dirKey = _linuxDirectoryMap[directory] ?? 'downloads';

    try {
      final String? path = await _channel.invokeMethod<String>('saveFile', {
        'bytes': bytes,
        'fileName': fileName,
        'directory': dirKey,
      });
      return path != null
          ? SaveResult.ok(path)
          : SaveResult.fail('Linux: saveFile returned null');
    } on PlatformException catch (e) {
      return SaveResult.fail('${e.code}: ${e.message}');
    } catch (e) {
      return SaveResult.fail(e.toString());
    }
  }
}
