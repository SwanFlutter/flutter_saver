import 'package:flutter/foundation.dart';

import '../enums/save_directory.dart';
import '../models/save_result.dart';

class WebSaver {
  static Future<SaveResult> saveFile({
    required Uint8List bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    if (kDebugMode) {
      debugPrint('[flutter_saver] WebSaver is not available on this platform.');
    }
    return SaveResult.fail('WebSaver is not supported on this platform.');
  }

  static Future<SaveResult> downloadFile({
    required String link,
    required String fileName,
    required SaveDirectory directory,
    List<String>? corsProxies,
  }) async {
    return SaveResult.fail('WebSaver is not supported on this platform.');
  }
}
