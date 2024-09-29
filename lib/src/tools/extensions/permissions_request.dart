// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles permissions based on the Android version.
///
/// Requests different permissions depending on the Android version.
Future<void> handlePermissions() async {
  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();

      if (statuses[Permission.storage]!.isGranted &&
          statuses[Permission.photos]!.isGranted &&
          statuses[Permission.videos]!.isGranted &&
          statuses[Permission.audio]!.isGranted) {
        // All permissions are granted
      } else if (statuses[Permission.storage]!.isDenied &&
          statuses[Permission.photos]!.isGranted &&
          statuses[Permission.videos]!.isGranted &&
          statuses[Permission.audio]!.isGranted) {
        // درخواست دسترسی برای مدیریت رسانه‌ها
        List<PermissionStatus> statuses = [
          await Permission.manageExternalStorage.request(),
          await Permission.storage.request(),
          await Permission.photos.request(),
          await Permission.videos.request(),
          await Permission.audio.request(),
        ];

        if (statuses == PermissionStatus.permanentlyDenied) {
          openAppSettings();
        }
      }
    }
    if (sdkInt >= 29) {
      // Request all necessary permissions for Android 10 (SDK 29) and above
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.camera,
        Permission.audio,
        Permission.manageExternalStorage, // For managing external storage
      ].request();

      // Check if any permission is permanently denied, then direct to app settings
      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        // If any permission is permanently denied, open app settings
        openAppSettings();
      } else {
        // Request any denied permissions
        if (statuses.values.any((status) => status.isDenied)) {
          await [
            Permission.storage,
            Permission.camera,
            Permission.audio,
            Permission.manageExternalStorage,
          ].request();
        }
      }
    } else {
      // Access request for camera
      // Request permissions for devices below Android 10
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.camera,
        Permission.audio,
      ].request();

      // Check if any permission is permanently denied, then direct to app settings
      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        openAppSettings();
      } else {
        // Request any denied permissions
        if (statuses.values.any((status) => status.isDenied)) {
          await [
            Permission.storage,
            Permission.camera,
            Permission.audio,
          ].request();
        }
      }
    }
  } else if (Platform.isIOS) {
    // Request permissions for photos, videos, and audio on iOS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.storage, // To handle saving files
      Permission.microphone, // For audio recording
    ].request();

    // Check if any permission is permanently denied, then open app settings
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      openAppSettings();
      return;
    }

    // Request any denied permissions
    if (statuses.values.any((status) => status.isDenied)) {
      await [
        Permission.photos,
        Permission.videos,
        Permission.storage,
        Permission.microphone,
      ].request();
    }
  } else if (Platform.isWindows) {
    // Permissions are not normally required on Windows, but should be checked
    debugPrint('No special permissions needed for Windows.');
  } else if (Platform.isMacOS) {
    // Request permissions for photos, videos, and audio on macOS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.storage, // To handle saving files
      Permission.microphone, // For audio recording
    ].request();

    // Check if any permission is permanently denied, then open app settings
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      openAppSettings();
      return;
    }

    // Request any denied permissions
    if (statuses.values.any((status) => status.isDenied)) {
      await [
        Permission.photos,
        Permission.videos,
        Permission.storage,
        Permission.microphone,
      ].request();
    }
  } else {
    debugPrint('Unsupported platform.');
  }
}
