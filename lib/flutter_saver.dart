// ignore_for_file: depend_on_referenced_packages

library flutter_saver;

import 'dart:io';
import 'dart:math';

import 'package:external_path/external_path.dart';
import 'package:external_path_ios_mac/external_path_ios_mac.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_saver/src/tools/tools.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

export 'package:external_path/external_path.dart';
export 'package:external_path_ios_mac/external_path_ios_mac.dart';
export 'package:permission_handler/permission_handler.dart';
export 'package:path/path.dart';

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
    String localFileName = "image_$randomFileName(lengthFileName)";

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
  /// - [pathDirectory]: Optional custom download directory path.
  ///   [pathDirectory] : ExternalPath.DIRECTORY_MUSIC , ExternalPath.DIRECTORY_PODCASTS , ExternalPath.DIRECTORY_RINGTONES , ExternalPath.DIRECTORY_ALARMS , ExternalPath.DIRECTORY_NOTIFICATIONS
  ///   ExternalPath.DIRECTORY_PICTURES , ExternalPath.DIRECTORY_MOVIES , ExternalPath.DIRECTORY_DOWNLOADS , ExternalPath.DIRECTORY_DCIM , ExternalPath.DIRECTORY_DOCUMENTS
  ///   ExternalPath.DIRECTORY_SCREENSHOTS , ExternalPath.DIRECTORY_AUDIOBOOKS.
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageAndroid({
    required File? fileImage,
    int lengthFileName = 5,
    String? fileName,
    String? type = 'jpg',
    String? pathDirectory,
  }) async {
    if (Platform.isAndroid) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt == 29) {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission not granted');
          }
        }
      }
    }

    PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus != PermissionStatus.granted) {
      PermissionStatus requestResult = await Permission.storage.request();
      if (requestResult != PermissionStatus.granted) {
        // Handle permission permanently denied (optional)
        openAppSettings();
      }
    }

    String filePath = '';
    String localFileName = "image_${randomFileName(lengthFileName)}";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isAndroid) {
        var downloadDirectoryAndroid =
            await ExternalPath.getExternalStoragePublicDirectory(
                pathDirectory ?? ExternalPath.DIRECTORY_DOWNLOADS);

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
  /// - [pathDirectory]: Optional custom download directory path.
  ///   [pathDirectory] :
  ///   'DIRECTORY_DOWNLOADS' , 'DIRECTORY_MUSIC', 'DIRECTORY_PODCASTS' , 'DIRECTORY_RINGTONES' , 'DIRECTORY_ALARMS' , 'DIRECTORY_NOTIFICATIONS' , 'DIRECTORY_PICTURES' , 'DIRECTORY_MOVIES' , 'DIRECTORY_DCIM' , 'DIRECTORY_DOCUMENTS', 'DIRECTORY_SCREENSHOTS', 'DIRECTORY_AUDIOBOOKS'
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageIos(
      {required File? fileImage,
      int lengthFileName = 5,
      String? fileName,
      String? type = 'jpg',
      String? pathDirectory}) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    final externalPathIosMacPlugin = ExternalPathIosMac();
    String filePath = '';
    String localFileName = "image_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isIOS) {
        var downloadDirectoryIos = pathDirectory ??
            await externalPathIosMacPlugin.getDirectoryPath(
                directory: pathDirectory ?? 'DIRECTORY_DOWNLOADS');
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
  /// - [pathDirectory]: Optional custom download directory path.
  ///   [pathDirectory] : "DIRECTORY_DOWNLOADS" , "DIRECTORY_PICTURES" , "DIRECTORY_MOVIES".
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveImageMacOs(
      {required File? fileImage,
      int lengthFileName = 5,
      String? fileName,
      String? type = 'jpg',
      String? pathDirectory}) async {
    final externalPathIosMacPlugin = ExternalPathIosMac();
    String filePath = '';
    String localFileName = "image_$randomFileName(lengthFileName)";

    String finalFilename = fileName ?? localFileName;

    try {
      if (Platform.isMacOS) {
        var downloadDirectoryMac = pathDirectory ??
            await externalPathIosMacPlugin.getDirectoryPathMacOs(
                directory: pathDirectory ?? 'DIRECTORY_DOWNLOADS');
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
  /// - [pathDirectory]: Optional custom download directory path.
  ///   [pathDirectory] : ExternalPath.DIRECTORY_MUSIC , ExternalPath.DIRECTORY_PODCASTS , ExternalPath.DIRECTORY_RINGTONES , ExternalPath.DIRECTORY_ALARMS , ExternalPath.DIRECTORY_NOTIFICATIONS
  ///   ExternalPath.DIRECTORY_PICTURES , ExternalPath.DIRECTORY_MOVIES , ExternalPath.DIRECTORY_DOWNLOADS , ExternalPath.DIRECTORY_DCIM , ExternalPath.DIRECTORY_DOCUMENTS
  ///   ExternalPath.DIRECTORY_SCREENSHOTS , ExternalPath.DIRECTORY_AUDIOBOOKS.
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveFileAndroid({
    required String link,
    String? pathDirectory,
  }) async {
    if (Platform.isAndroid) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt == 29) {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission not granted');
          }
        }
      }
    }

    PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus != PermissionStatus.granted) {
      PermissionStatus requestResult = await Permission.storage.request();
      if (requestResult != PermissionStatus.granted) {
        // Handle permission permanently denied (optional)
        openAppSettings();
      }
    }

    File? filePath;

    var downloadDirectoryAndroid =
        await ExternalPath.getExternalStoragePublicDirectory(
      pathDirectory ?? ExternalPath.DIRECTORY_DOWNLOADS,
    );

    try {
      var response = await http.get(Uri.parse(link));

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      String fileName = path.basename(link);
      // ignore: unused_local_variable
      String extension = path.extension(fileName);
      String baseName = path.basenameWithoutExtension(fileName);

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
  /// - [pathDirectory]: Optional custom download directory path.
  ///   [pathDirectory] :
  ///   'DIRECTORY_DOWNLOADS' , 'DIRECTORY_MUSIC', 'DIRECTORY_PODCASTS' , 'DIRECTORY_RINGTONES' , 'DIRECTORY_ALARMS' , 'DIRECTORY_NOTIFICATIONS' , 'DIRECTORY_PICTURES' , 'DIRECTORY_MOVIES' , 'DIRECTORY_DCIM' , 'DIRECTORY_DOCUMENTS', 'DIRECTORY_SCREENSHOTS', 'DIRECTORY_AUDIOBOOKS'
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveFileIos(
      {required String link, String? pathDirectory}) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }
    final externalPathIosMacPlugin = ExternalPathIosMac();

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

      String fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (Platform.isIOS) {
        var downloadDirectoryIos = pathDirectory ??
            await externalPathIosMacPlugin.getDirectoryPath(
                directory: pathDirectory ?? 'DIRECTORY_DOWNLOADS');
        filePath =
            File(path.join(downloadDirectoryIos!, '$baseName$fileExtension'));
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
  /// - [pathDirectory]: Optional custom download directory path.
  ///   [pathDirectory] : "DIRECTORY_DOWNLOADS" , "DIRECTORY_PICTURES" , "DIRECTORY_MOVIES".
  /// Returns `true` if the file was saved successfully, otherwise `false`.
  static Future<bool> saveFileMac(
      {required String link, String? pathDirectory}) async {
    final externalPathIosMacPlugin = ExternalPathIosMac();
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

      String fileExtension =
          fileExtensions[response.headers['content-type']] ?? '.png';

      if (Platform.isMacOS) {
        var downloadDirectoryMac = pathDirectory ??
            await externalPathIosMacPlugin.getDirectoryPathMacOs(
                directory: pathDirectory ?? 'DIRECTORY_DOWNLOADS');
        filePath =
            File(path.join(downloadDirectoryMac!, '$baseName$fileExtension'));
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
