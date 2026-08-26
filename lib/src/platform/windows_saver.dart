import 'package:flutter/services.dart';

import '../enums/save_directory.dart';
import '../models/save_result.dart';

/// Windows implementation of flutter_saver.
///
/// Delegates to the native C++ plugin via MethodChannel, which:
///  - Resolves the Downloads folder via SHGetKnownFolderPath (FOLDERID_Downloads).
///  - Writes the file on a background thread and marshals the result back to
///    the platform thread (thread-safe via a message-only HWND).
///  - Handles unique file naming (auto-rename on collision).
///
/// All [SaveDirectory] values other than [SaveDirectory.downloads] are not
/// natively supported on Windows and fall back to Downloads inside the native
/// plugin. A debug warning is printed in that case.
class WindowsSaver {
  static const _channel = MethodChannel('flutter_saver');

  static Future<SaveResult> saveFile({
    required Uint8List bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    if (directory != SaveDirectory.downloads) {
      assert(() {
        // ignore: avoid_print
        print(
          '[flutter_saver] Windows: SaveDirectory.$directory is not natively '
          'supported — falling back to Downloads.',
        );
        return true;
      }());
    }

    try {
      final String? path = await _channel.invokeMethod<String>('saveFile', {
        'bytes': bytes,
        'fileName': fileName,
        'directory': 'downloads', // Windows always uses Downloads
      });
      return path != null
          ? SaveResult.ok(path)
          : SaveResult.fail('Windows: saveFile returned null');
    } on PlatformException catch (e) {
      return SaveResult.fail('${e.code}: ${e.message}');
    } catch (e) {
      return SaveResult.fail(e.toString());
    }
  }
}
