import 'dart:io';

/// Runtime platform detection for native (VM/`dart:io`) builds.
class PlatformInfo {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static String get operatingSystem => Platform.operatingSystem;
}
