import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_saver_method_channel.dart';

/// Platform interface for flutter_saver.
///
/// Concrete implementations (Web shim) extend this class.
/// The main logic lives in [FlutterSaver] (src/flutter_saver_base.dart) which
/// dispatches directly to platform-specific implementations without going
/// through this interface for Android / iOS / macOS / Windows.
abstract class FlutterSaverPlatform extends PlatformInterface {
  /// Constructs a [FlutterSaverPlatform].
  FlutterSaverPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSaverPlatform _instance = MethodChannelFlutterSaver();

  /// The default instance of [FlutterSaverPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSaver].
  static FlutterSaverPlatform get instance => _instance;

  /// Sets the instance of [FlutterSaverPlatform] to use.
  ///
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSaverPlatform] when they
  /// register themselves.
  static set instance(FlutterSaverPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
