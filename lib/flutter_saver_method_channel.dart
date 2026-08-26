import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'flutter_saver_platform_interface.dart';

/// Default [FlutterSaverPlatform] implementation using [MethodChannel].
///
/// This class exists as the default instance for the platform interface.
/// Actual save/download logic is handled by [FlutterSaver] in
/// src/flutter_saver_base.dart, which dispatches to platform-specific
/// classes (AndroidChannel, IosChannel, MacosChannel, WindowsSaver, WebSaver)
/// without going through this channel.
class MethodChannelFlutterSaver extends FlutterSaverPlatform {
  /// Creates a [MethodChannelFlutterSaver] instance.
  MethodChannelFlutterSaver();

  /// The [MethodChannel] used to communicate with the native plugin.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_saver');
}
