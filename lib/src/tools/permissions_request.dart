import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles permissions based on the Android version.
///
/// Requests different permissions depending on the Android version.
Future<void> handlePermissions() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  if (sdkInt <= 28) {
    await _requestPermissions(
      permissions: [Permission.camera, Permission.storage],
      versionLabel: 'Android 9 and below',
    );
  } else if (sdkInt >= 29 && sdkInt <= 32) {
    await _requestPermissions(
      permissions: [Permission.camera, Permission.storage],
      versionLabel: 'Android 10 to 12',
    );
  } else if (sdkInt >= 33) {
    await _requestPermissions(
      permissions: [Permission.photos, Permission.videos, Permission.camera],
      versionLabel: 'Android 13 and above',
    );
  } else {
    debugPrint('Unsupported Android version: SDK $sdkInt');
  }
}

/// Requests permissions and prints their statuses.
///
/// Parameters:
/// - [permissions]: A list of permissions to request.
/// - [versionLabel]: A label for the Android version, used for debug prints.
Future<void> _requestPermissions({
  required List<Permission> permissions,
  required String versionLabel,
}) async {
  final statuses = await permissions.request();

  // Print the status of each permission
  for (var permission in permissions) {
    final status = statuses[permission] ?? PermissionStatus.denied;
    if (status.isGranted) {
      debugPrint('$permission granted for $versionLabel.');
    } else {
      debugPrint('$permission not granted for $versionLabel.');
    }
  }
}
