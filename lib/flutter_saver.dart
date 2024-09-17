library flutter_saver;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_saver/src/tools/extensions/files_extensions.dart';
import 'package:flutter_saver/src/tools/extensions/string_extensions.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'package:external_path_ios_mac/external_path_ios_mac.dart';

export 'package:external_path/external_path.dart';
export 'package:external_path_ios_mac/external_path_ios_mac.dart';
export 'package:path/path.dart';
export 'package:permission_handler/permission_handler.dart';

class FlutterSaver {
  /// Gets the directory path based on the platform.
  static Future<String?> getDirectoryPath(
    String platformDirectory,
    String? pathDirectory,
  ) async {
    if (Platform.isAndroid) {
      return ExternalPath.getExternalStoragePublicDirectory(
          pathDirectory ?? platformDirectory);
    } else if (Platform.isIOS) {
      final externalPathPlugin = ExternalPathIosMac();
      return await externalPathPlugin.getDirectoryPath(
        directory: pathDirectory ?? platformDirectory,
      );
    } else if (Platform.isMacOS) {
      final externalPathPlugin = ExternalPathIosMac();
      return await externalPathPlugin.getDirectoryPathMacOs(
          directory: pathDirectory ?? platformDirectory);
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Saves an array of image files to the downloads folder for various platforms.
  static Future<List<({bool state, File? file})>> saveImages({
    required List<File> files,
    int lengthFileName = 5,
    String? fileName,
    String? type = 'jpg',
    String? pathDirectory,
  }) async {
    final List<({bool state, File? file})> results = [];

    for (final fileImage in files) {
      String filePath;

      String randomName = "".randomFileName(lengthFileName);
      String dateNow = DateTime.now().toIso8601String().replaceAll(':', '-');

      String finalFilename = fileName ?? "$randomName$dateNow";

      try {
        String directoryPath;
        if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
          directoryPath = await getDirectoryPath(
                ExternalPath.DIRECTORY_DOWNLOADS,
                pathDirectory,
              ) ??
              '';
          filePath = '$directoryPath/$finalFilename.$type';
        } else if (kIsWeb || Platform.isWindows) {
          final downloadDirectory = await getDownloadsDirectory();
          filePath = '${downloadDirectory!.path}/$finalFilename.$type';
        } else {
          throw UnsupportedError('Unsupported platform');
        }

        final savedFile = await fileImage.copy(filePath);
        results.add((state: true, file: savedFile));
      } catch (e, stackTrace) {
        debugPrint('Error saving image: $e');
        if (kDebugMode) {
          print('Stack Trace: $stackTrace');
        }
        results.add((state: false, file: null));
      }
    }

    return results;
  }

  /// Saves any file from a URL to the downloads folder for various platforms.

  static Future<({bool state, File? file})> saveFile({
    required String link,
    String? pathDirectory,
  }) async {
    File? filePath;
    String fileExtension;

    try {
      final response = await http.get(Uri.parse(link));

      if (response.statusCode != 200) {
        throw Exception('Failed to load file: ${response.statusCode}');
      }

      final fileName = path.basename(link);
      final baseName = path.basenameWithoutExtension(fileName);

      fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          kIsWeb ||
          Platform.isWindows) {
        final directoryPath = await getDirectoryPath(
                ExternalPath.DIRECTORY_DOWNLOADS, pathDirectory) ??
            '';
        filePath = File(path.join(directoryPath, '$baseName$fileExtension'));
        debugPrint("File path: $filePath");

        await filePath.writeAsBytes(response.bodyBytes);
        return (state: true, file: filePath);
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    } catch (e, stackTrace) {
      debugPrint('Error during file download: $e');
      if (kDebugMode) {
        print('Stack Trace: $stackTrace');
      }
      return (state: false, file: null);
    }
  }
}
