// ignore_for_file: depend_on_referenced_packages

library flutter_saver;

import 'dart:io';
import 'dart:math';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:android_path_provider/android_path_provider.dart';
export 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

//// A package to save images and files to the downloads folder.
///
/// Example:
/// ```dart
/// import 'package:flutter_saver/flutter_saver.dart';
///
/// await FlutterSaver.saveImageWindowsWeb(
///   fileImage: fileImage,
///   fileName: 'example',
///   type: 'jpg',
/// );
/// ```
class FlutterSaver {
  /// Saves an image file to the downloads folder for Windows or Web.
  ///
  /// Parameters:
  /// - [fileImage]: The image file to be saved.
  /// - [lengthFileName]: The length of the randomly generated file name (default is 5).
  /// - [fileName]: Optional custom file name.
  /// - [type]: The file extension/type (default is 'jpg').
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageWindowsWeb({
    required File? fileImage,
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

      await fileImage!.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  /// Saves an image file to the downloads folder for Android.
  ///
  /// Parameters:
  /// - [fileImage]: The image file to be saved.
  /// - [lengthFileName]: The length of the randomly generated file name (default is 5).
  /// - [fileName]: Optional custom file name.
  /// - [type]: The file extension/type (default is 'jpg').
  /// - [pathDir]: Optional custom download directory path.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageAndroid({
    required File? fileImage,
    int lengthFileName = 5,
    String? fileName,
    String? type = 'jpg',
    AndroidPathProvider? pathDir,
  }) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    String filePath = '';
    String localFileName = "image_${randomFileName(lengthFileName)}";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isAndroid) {
        var downloadDirectoryAndroid =
            pathDir ?? await AndroidPathProvider.downloadsPath;

        filePath = '$downloadDirectoryAndroid/$finalFilename.$type';
        debugPrint("defaultPath: $filePath");
      } else {
        throw Exception('Error saving image: Unsupported platform');
      }

      await fileImage!.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  /// Saves an image file to the downloads folder for iOS.
  ///
  /// Parameters:
  /// - [fileImage]: The image file to be saved.
  /// - [lengthFileName]: The length of the randomly generated file name (default is 5).
  /// - [fileName]: Optional custom file name.
  /// - [type]: The file extension/type (default is 'jpg').
  /// - [pathDir]: Optional custom download directory path.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageIos(
      {required File? fileImage,
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

      await fileImage!.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  /// Saves an image file to the downloads folder for Mac.
  ///
  /// Parameters:
  /// - [fileImage]: The image file to be saved.
  /// - [lengthFileName]: The length of the randomly generated file name (default is 5).
  /// - [fileName]: Optional custom file name.
  /// - [type]: The file extension/type (default is 'jpg').
  /// - [pathDir]: Optional custom download directory path.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageMacOs(
      {required File? fileImage,
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

      await fileImage!.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

  /// Saves any file from a URL to the downloads folder for Windows or Web.
  ///
  /// Parameters:
  /// - [link]: The URL of the file to be downloaded.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
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

  /// Saves any file from a URL to the downloads folder for Android.
  ///
  /// Parameters:
  /// - [link]: The URL of the file to be downloaded.
  /// - [pathDir]: Optional custom download directory path.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveFileAndroid({
    required String link,
    AndroidPathProvider? pathDir,
  }) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    File? filePath;

    var downloadDirectoryAndroid =
        pathDir ?? await AndroidPathProvider.downloadsPath;

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

  /// Saves any file from a URL to the downloads folder for iOS.
  ///
  /// Parameters:
  /// - [link]: The URL of the file to be downloaded.
  /// - [pathDir]: Optional custom download directory path.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveFileIos({
    required String link,
  }) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    final Directory downloadDirectoryIos =
        await getApplicationDocumentsDirectory();
    File? filePath;

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

      if (Platform.isIOS) {
        filePath = File(
            path.join(downloadDirectoryIos.path, '$baseName$fileExtension'));
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

  /// Saves any file from a URL to the downloads folder for Mac.
  ///
  /// Parameters:
  /// - [link]: The URL of the file to be downloaded.
  /// - [pathDir]: Optional custom download directory path.
  ///
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveFileMac({
    required String link,
  }) async {
    final Directory? downloadDirectoryMac = await getDownloadsDirectory();
    File? filePath;

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

      if (Platform.isMacOS) {
        filePath = File(
            path.join(downloadDirectoryMac!.path, '$baseName$fileExtension'));
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

/// Generates a random file name with a given length.
///
/// Parameters:
/// - [length]: The length of the random file name.
///
/// Returns a randomly generated file name.
String randomFileName(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}
