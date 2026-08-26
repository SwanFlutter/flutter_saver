import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web plugin registrant for flutter_saver.
///
/// Referenced from `pubspec.yaml` → `pluginClass: FlutterSaverWeb` /
/// `fileName: flutter_saver_web.dart` so the generated web plugin registrant
/// can wire this package up automatically.
///
/// All web functionality lives in `lib/src/platform/web_saver.dart` and is
/// exposed through static methods (no method channel), so registration is
/// intentionally a no-op.
class FlutterSaverWeb {
  static void registerWith(Registrar registrar) {
    // No method channel is used on web — see class docs.
  }
}
