import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Returns a map of file extensions and their corresponding file name extensions.
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
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': '.xlsx',
  '.dwg': '.dwg',
};

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

Future<void> handlePermissions() async {
  // Get device information
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  // Get the Android version of the device
  int sdkInt = androidInfo.version.sdkInt;

  // Categorize devices based on Android version
  if (sdkInt <= 28) {
    // Android 9 (SDK 28) and below
    await _requestPermissionsBelowAndroid10();
  } else if (sdkInt >= 29 && sdkInt <= 32) {
    // Android 10 to 12
    await _requestPermissionsAndroid10to12();
  } else if (sdkInt >= 33) {
    // Android 13 (SDK 33) and above
    await _requestPermissionsAboveAndroid13();
  }
}

// Request permissions for Android 9 and below
Future<void> _requestPermissionsBelowAndroid10() async {
  // Check if permissions have already been granted
  if (await Permission.camera.isGranted && await Permission.storage.isGranted) {
    debugPrint(
        'All necessary permissions for Android 9 and below have already been granted.');
    return;
  }

  // Requested if permissions not granted
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
  ].request();

  // Check the status of each license
  statuses.forEach((permission, status) {
    if (status.isGranted) {
      debugPrint('$permission is given for Android 9 and below.');
    } else {
      debugPrint('$permission not given for Android 9 and below.');
    }
  });
}

// Request permissions for Android 10 to 12
Future<void> _requestPermissionsAndroid10to12() async {
  // Check if permissions have already been granted
  if (await Permission.camera.isGranted && await Permission.storage.isGranted) {
    debugPrint(
        'All necessary permissions for Android 10 to 12 have already been granted.');
    return;
  }

  // Requested if permissions not granted
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
  ].request();

  // Check the status of each license
  statuses.forEach((permission, status) {
    if (status.isGranted) {
      debugPrint('$permission is given for Android 10 to 12.');
    } else {
      debugPrint('$permission not given for Android 10 to 12.');
    }
  });
}

// Request permissions for Android 13 and above
Future<void> _requestPermissionsAboveAndroid13() async {
  // Check if new permissions have been granted
  if (await Permission.photos.isGranted &&
      await Permission.videos.isGranted &&
      await Permission.camera.isGranted) {
    debugPrint(
        'All necessary permissions have been granted for Android 13 and above.');
    return;
  }

// Request new permissions for Android 13 and above
  Map<Permission, PermissionStatus> statuses = await [
    Permission.photos,
    Permission.videos,
    Permission.camera,
  ].request();

  // Check the status of each license
  statuses.forEach((permission, status) {
    if (status.isGranted) {
      debugPrint('$permission is given for Android 13 and above.');
    } else {
      debugPrint('$permission not given for Android 13 and above.');
    }
  });
}
