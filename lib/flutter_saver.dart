// ignore_for_file: depend_on_referenced_packages

library flutter_saver;

import 'dart:io';
import 'dart:math';

import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:external_path/external_path.dart';
export 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A package to save image and files to downloads folder.
///
///Example:
/// ```dart
///
/// import 'package:flutter_saver/flutter_saver.dart';
///
/// await FlutterSaver.saveImageWindowsWeb(
///   fileImage: fileImage,
///   fileName: 'example',
///   type: 'jpg',
/// );
///```
///
class FlutterSaver {
  // save image file

  static Future<bool> saveImageWindowsWeb({
    required File fileImage,
    int lengthFileName = 5,
    String? fileName,
    String? type = 'jpg',
  }) async {
    String filePath = '';
    String localFileName = "iamage_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (kIsWeb || Platform.isWindows) {
        Directory? downloadDirectoryWindows = await getDownloadsDirectory();
        filePath = '${downloadDirectoryWindows!.path}/$finalFilename.$type';
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Error saving image: $e');
      }

      await fileImage.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  static Future<bool> saveImageAndroid({
    required File fileImage,
    int lengthFileName = 5,
    String? fileName,
    String? type = 'jpg',
    ExternalPath? pathDir,
  }) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    String filePath = '';
    String localFileName = "iamage_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isAndroid) {
        var downloadDirectoryAndroid = pathDir ??
            await ExternalPath.getExternalStoragePublicDirectory(
                ExternalPath.DIRECTORY_DOWNLOADS);
        filePath =
            '${downloadDirectoryAndroid.toString()}/$finalFilename.$type';
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Error saving image: $e');
      }

      await fileImage.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  static Future<bool> saveImageIos(
      {required File fileImage,
      int lengthFileName = 5,
      String? fileName,
      String? type = 'jpg',
      PathProviderPlatform? pathDir}) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    String filePath = '';
    String localFileName = "iamage_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isIOS) {
        var downloadDirectoryIos = pathDir ?? await provider.getDownloadsPath();
        filePath = '${downloadDirectoryIos.toString()}/$finalFilename.$type';
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Error saving image: $e');
      }

      await fileImage.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  static Future<bool> saveImageMacOs(
      {required File fileImage,
      int lengthFileName = 5,
      String? fileName,
      String? type = 'jpg',
      PathProviderPlatform? pathDir}) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    String filePath = '';
    String localFileName = "iamage_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isMacOS) {
        var downloadDirectoryMac = pathDir ?? await provider.getDownloadsPath();
        filePath = '${downloadDirectoryMac.toString()}/$finalFilename.$type';
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Error saving image: $e');
      }

      await fileImage.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

// save all file//

  static Future<bool> saveFileWindowsWeb({required String link}) async {
    File? filePath;
    Directory? downloadDirectory = await getDownloadsDirectory();

    try {
      var response = await http.get(Uri.parse(link));

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      String fileName = path.basename(link);
      // ignore: unused_local_variable
      String extension = path.extension(fileName);
      String baseName = path.basenameWithoutExtension(fileName);

      Map<String, String> fileExtensions = {
        'image/jpeg': '.jpg',
        'image/png': '.png',
        'video/mp4': '.mp4',
        'application/pdf': '.pdf',
        'application/zip': '.zip',
        'image/gif': '.gif',
        'image/webp': '.webp',
        'image/svg+xml': '.svg',
        'image/tiff': '.tiff',
        'image/vnd.microsoft.icon': '.ico',
        'image/vnd.djvu': '.djvu',
        'image/vnd.adobe.photoshop': '.psd',
        'image/x-ms-bmp': '.bmp',
        'image/x-icon': '.ico',
        'image/x-ico': '.ico',
        'image/x-xbitmap': '.xbm',
        'image/x-png': '.png',
        'application/x-msdownload': '.exe',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation':
            '.pptx',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            '.docx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
            '.xlsx',
        '.dwg': '.dwg',
      };

      String fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (kIsWeb || Platform.isWindows) {
        filePath =
            File(path.join(downloadDirectory!.path, '$baseName$fileExtension'));
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Platform not supported');
      }

      await filePath.writeAsBytes(response.bodyBytes);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error during image download: $e');
        print('Stack Trace: $stackTrace');
      }
      return false;
    }
  }

  // save all file android

  static Future<bool> saveFileAndroid({
    required String link,
    ExternalPath? pathDir,
  }) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    File? filePath;

    var downloadDirectoryAndroid = pathDir ??
        await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOADS);

    try {
      var response = await http.get(Uri.parse(link));

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      String fileName = path.basename(link);
      // ignore: unused_local_variable
      String extension = path.extension(fileName);
      String baseName = path.basenameWithoutExtension(fileName);

      Map<String, String> fileExtensions = {
        'image/jpeg': '.jpg',
        'image/png': '.png',
        'video/mp4': '.mp4',
        'application/pdf': '.pdf',
        'application/zip': '.zip',
        'image/gif': '.gif',
        'image/webp': '.webp',
        'image/svg+xml': '.svg',
        'image/tiff': '.tiff',
        'image/vnd.microsoft.icon': '.ico',
        'image/vnd.djvu': '.djvu',
        'image/vnd.adobe.photoshop': '.psd',
        'image/x-ms-bmp': '.bmp',
        'image/x-icon': '.ico',
        'image/x-ico': '.ico',
        'image/x-xbitmap': '.xbm',
        'image/x-png': '.png',
        'application/x-msdownload': '.exe',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation':
            '.pptx',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            '.docx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
            '.xlsx',
        '.dwg': '.dwg',
      };

      String fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (Platform.isAndroid) {
        filePath = File(path.join(
            downloadDirectoryAndroid.toString(), '$baseName$fileExtension'));
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Platform not supported');
      }

      await filePath.writeAsBytes(response.bodyBytes);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error during image download: $e');
        print('Stack Trace: $stackTrace');
      }
      return false;
    }
  }

  // save all file ios
  static Future<bool> saveFileIos(
      {required String link, PathProviderPlatform? pathDir}) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    File? filePath;
    // ignore: unnecessary_null_comparison

    var downloadDirectoryIos = pathDir ?? await provider.getDownloadsPath();

    try {
      var response = await http.get(Uri.parse(link));

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      String fileName = path.basename(link);
      // ignore: unused_local_variable
      String extension = path.extension(fileName);
      String baseName = path.basenameWithoutExtension(fileName);

      Map<String, String> fileExtensions = {
        'image/jpeg': '.jpg',
        'image/png': '.png',
        'video/mp4': '.mp4',
        'application/pdf': '.pdf',
        'application/zip': '.zip',
        'image/gif': '.gif',
        'image/webp': '.webp',
        'image/svg+xml': '.svg',
        'image/tiff': '.tiff',
        'image/vnd.microsoft.icon': '.ico',
        'image/vnd.djvu': '.djvu',
        'image/vnd.adobe.photoshop': '.psd',
        'image/x-ms-bmp': '.bmp',
        'image/x-icon': '.ico',
        'image/x-ico': '.ico',
        'image/x-xbitmap': '.xbm',
        'image/x-png': '.png',
        'application/x-msdownload': '.exe',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation':
            '.pptx',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            '.docx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
            '.xlsx',
        '.dwg': '.dwg',
      };

      String fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (Platform.isAndroid) {
        filePath = File(path.join(
            downloadDirectoryIos.toString(), '$baseName$fileExtension'));
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Platform not supported');
      }

      await filePath.writeAsBytes(response.bodyBytes);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error during image download: $e');
        print('Stack Trace: $stackTrace');
      }
      return false;
    }
  }

  static Future<bool> saveFileMac(
      {required String link, PathProviderPlatform? pathDir}) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    File? filePath;
    var downloadDirectoryMac = pathDir ?? await provider.getDownloadsPath();

    try {
      var response = await http.get(Uri.parse(link));

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      String fileName = path.basename(link);
      // ignore: unused_local_variable
      String extension = path.extension(fileName);
      String baseName = path.basenameWithoutExtension(fileName);

      Map<String, String> fileExtensions = {
        'image/jpeg': '.jpg',
        'image/png': '.png',
        'video/mp4': '.mp4',
        'application/pdf': '.pdf',
        'application/zip': '.zip',
        'image/gif': '.gif',
        'image/webp': '.webp',
        'image/svg+xml': '.svg',
        'image/tiff': '.tiff',
        'image/vnd.microsoft.icon': '.ico',
        'image/vnd.djvu': '.djvu',
        'image/vnd.adobe.photoshop': '.psd',
        'image/x-ms-bmp': '.bmp',
        'image/x-icon': '.ico',
        'image/x-ico': '.ico',
        'image/x-xbitmap': '.xbm',
        'image/x-png': '.png',
        'application/x-msdownload': '.exe',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation':
            '.pptx',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            '.docx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
            '.xlsx',
        '.dwg': '.dwg',
      };

      String fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (Platform.isAndroid) {
        filePath = File(path.join(
            downloadDirectoryMac.toString(), '$baseName$fileExtension'));
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Platform not supported');
      }

      await filePath.writeAsBytes(response.bodyBytes);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error during image download: $e');
        print('Stack Trace: $stackTrace');
      }
      return false;
    }
  }
}

List<String> randomFileName(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return List.generate(
      chars.length, (index) => chars[random.nextInt(chars.length)]);
}
