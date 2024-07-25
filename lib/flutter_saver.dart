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

/// A package to save image and files to downloads folder.
///
///Example:
/// ```dart
///
/// import 'package:flutter_saver/flutter_saver.dart';
///
/// await FlutterSaver.saveImageFile(
///   fileImage: fileImage,
///   fileName: 'example',
///   type: 'jpg',
/// );
///```
///
class FlutterSaver {
  // save image file
  static Future<bool> saveImageFile({
    required File fileImage,
    int lengthFileName = 5,
    String? fileName,
    String? type = 'jpg',
  }) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    String filePath = '';
    String localFileName = "iamage_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (kIsWeb || Platform.isWindows) {
        Directory? downloadDirectoryWindows = await getDownloadsDirectory();
        filePath = '${downloadDirectoryWindows!.path}/$finalFilename.$type';
        debugPrint("defaultPath: $filePath");
      } else {
        switch (Platform.operatingSystem) {
          case 'android':
            String? downloadDirectoryAndroid =
                await AndroidPathProvider.downloadsPath;
            filePath = '$downloadDirectoryAndroid/$finalFilename.$type';
            debugPrint("defaultPath: $filePath");
            break;
          case 'ios':
            String? downloadDirectoryIos = await provider.getDownloadsPath();
            filePath = '$downloadDirectoryIos/$finalFilename.$type';
            debugPrint("defaultPath: $filePath");
            break;
          case 'macos':
            String? downloadDirectoryMac = await provider.getDownloadsPath();
            filePath = '$downloadDirectoryMac/$finalFilename.$type';
            debugPrint("defaultPath: $filePath");
            break;
          default:
            final Directory defaultDownloadDirectory =
                Directory('/storage/emulated/0/Download');
            filePath = '${defaultDownloadDirectory.path}/$finalFilename.$type';
            debugPrint("defaultPath: $filePath");
        }
      }

      await fileImage.copy(filePath);
      return true;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return false;
    }
  }

// save all file

  static Future<bool> saveAllFilesNetwork(String imageLink) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;

    File? filePath;
    Directory? downloadDirectory = await getDownloadsDirectory();
    String? downloadDirectoryAndroid = await AndroidPathProvider.downloadsPath;
    String? downloadDirectoryIos = await provider.getDownloadsPath();
    String? downloadDirectoryMac = await provider.getDownloadsPath();

    try {
      var response = await http.get(Uri.parse(imageLink));

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      String fileName = path.basename(imageLink);
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
        downloadDirectory = await getDownloadsDirectory();
        filePath =
            File(path.join(downloadDirectory!.path, '$baseName$fileExtension'));
        debugPrint("defaultPath: $filePath");
      } else {
        switch (Platform.operatingSystem) {
          case "android":
            filePath = File(
                path.join(downloadDirectoryAndroid, '$baseName$fileExtension'));
            debugPrint("defaultPath: $filePath");
            break;
          case "ios":
            filePath = File(
                path.join(downloadDirectoryIos!, '$baseName$fileExtension'));
            debugPrint("defaultPath: $filePath");
            break;
          case "macos":
            filePath = File(
                path.join(downloadDirectoryMac!, '$baseName$fileExtension'));
            debugPrint("defaultPath: $filePath");
            break;

          default:
            final Directory defaultDownloadDirectory =
                Directory('/storage/emulated/0/Download');
            filePath = File(path.join(
                defaultDownloadDirectory.path, '$baseName$fileExtension'));
            debugPrint("defaultPath: $filePath");
        }
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
