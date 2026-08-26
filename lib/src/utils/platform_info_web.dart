/// Runtime platform detection stub for Web builds, where `dart:io` is
/// unavailable. Every native flag is `false` and the OS reports as `web`.
class PlatformInfo {
  static const bool isAndroid = false;
  static const bool isIOS = false;
  static const bool isMacOS = false;
  static const bool isWindows = false;
  static const bool isLinux = false;
  static const String operatingSystem = 'web';
}
