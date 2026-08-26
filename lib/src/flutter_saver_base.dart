import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'enums/save_directory.dart';
import 'models/save_result.dart';
import 'platform/android_channel.dart';
import 'platform/ios_channel.dart';
import 'platform/linux_saver.dart';
import 'platform/macos_channel.dart';
import 'platform/web_saver_stub.dart'
    if (dart.library.js_interop) 'platform/web_saver.dart';
import 'platform/windows_saver.dart';
import 'utils/file_naming.dart';
import 'utils/mime_type_map.dart';
import 'utils/platform_info.dart';

/// The main entry point for `flutter_saver`.
///
/// All methods are static and platform-agnostic; platform detection happens
/// transparently inside this class.
class FlutterSaver {
  FlutterSaver._();

  /// **Web only:** CORS proxies tried (in order) when `downloadFile` hits a
  /// host that does not send `Access-Control-Allow-Origin` — in that case no
  /// JavaScript (this plugin or any other) can read the file bytes, so the
  /// URL is re-fetched through a proxy that re-serves it with CORS headers
  /// and downloaded as a Blob.
  ///
  /// - `{url}` is replaced with the URL-encoded target link.
  /// - `{rawUrl}` is replaced with the plain, unencoded link.
  ///
  /// Point it at your own proxy for production apps (privacy: public proxies
  /// see the fetched URLs), or set it to an empty list to disable proxy
  /// fallback entirely — non-CORS hosts then open in a new tab instead.
  static List<String> webCorsProxies = [
    'https://cors.eu.org/{rawUrl}',
    'https://api.codetabs.com/v1/proxy?quest={url}',
    'https://api.allorigins.win/raw?url={url}',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves a local file (provided as [bytes]) to device storage.
  ///
  /// - [bytes]      : Raw file content.
  /// - [fileName]   : Optional. If omitted a random name is generated.
  ///                  Should include the extension (e.g. `photo.jpg`).
  /// - [directory]  : Target directory (default: [SaveDirectory.downloads]).
  ///
  /// Returns a [SaveResult] with [SaveResult.success] = `true` and
  /// [SaveResult.filePath] set on success; or [SaveResult.error] on failure.
  /// On Web, [SaveResult.filePath] is always `null` (browser handles saving).
  static Future<SaveResult> saveFile({
    required Uint8List bytes,
    String? fileName,
    SaveDirectory directory = SaveDirectory.downloads,
  }) async {
    final name = _resolveName(fileName, null);
    return _dispatch(bytes: bytes, fileName: name, directory: directory);
  }

  /// Saves a file provided as an [XFile] to device storage — the natural
  /// companion to `image_picker`: feed the photo taken with the device
  /// camera (or picked from the gallery) straight into flutter_saver.
  ///
  /// Works on **every** platform: the bytes are read via
  /// `file.readAsBytes()` and handed to [saveFile].
  ///
  /// - [file]     : The picked/captured file (e.g. from `ImagePicker`).
  /// - [fileName] : Optional. Inferred from the XFile name/path/MIME type
  ///                when omitted.
  /// - [directory]: Target directory (default: [SaveDirectory.downloads]).
  ///
  /// Returns a [SaveResult] with the outcome of the operation.
  static Future<SaveResult> saveXFile(
    XFile file, {
    String? fileName,
    SaveDirectory directory = SaveDirectory.downloads,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return SaveResult.fail('saveXFile: the file is empty.');
      }
      final name = _resolveXFileName(file, fileName);
      return await _dispatch(
        bytes: bytes,
        fileName: name,
        directory: directory,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[flutter_saver] saveXFile error: $e');
      return SaveResult.fail(e.toString());
    }
  }

  /// Downloads a file from [link] and saves it to device storage.
  ///
  /// - [link]     : The URL of the remote file.
  /// - [fileName] : Optional. Inferred from URL path or `Content-Type` if
  ///                omitted.
  /// - [directory]: Target directory (default: [SaveDirectory.downloads]).
  ///
  /// Returns a [SaveResult] with the outcome of the operation.
  ///
  /// **Web note:** The file is fetched and handed to the browser as a Blob,
  /// which downloads **every** format (image, video, audio, pdf, zip, …)
  /// with the suggested [fileName]. If the remote host does not allow CORS
  /// (`Access-Control-Allow-Origin`), the URL is re-fetched through the
  /// proxies in [FlutterSaver.webCorsProxies] so a real download still
  /// happens; only when every proxy fails does the link open in a new tab
  /// (where the user can save it manually with Ctrl+S / ⌘S).
  static Future<SaveResult> downloadFile({
    required String link,
    String? fileName,
    SaveDirectory directory = SaveDirectory.downloads,
  }) async {
    if (kIsWeb) {
      final resolvedName = fileName ?? _buildNameFromUrl(link, '');
      return WebSaver.downloadFile(
        link: link,
        fileName: resolvedName,
        directory: directory,
        corsProxies: webCorsProxies,
      );
    }

    // Native platforms: plain HTTP fetch then save to disk.
    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode != 200) {
        return SaveResult.fail(
          'HTTP ${response.statusCode}: failed to download $link',
        );
      }

      final contentType =
          response.headers['content-type']?.split(';').first.trim() ?? '';

      final resolvedName = fileName ?? _buildNameFromUrl(link, contentType);

      return await _dispatch(
        bytes: response.bodyBytes,
        fileName: resolvedName,
        directory: directory,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[flutter_saver] downloadFile error: $e');
      return SaveResult.fail(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Dispatches the save operation to the correct platform implementation.
  static Future<SaveResult> _dispatch({
    required Uint8List bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    try {
      if (kIsWeb) {
        return await WebSaver.saveFile(
          bytes: bytes,
          fileName: fileName,
          directory: directory,
        );
      }

      if (PlatformInfo.isAndroid) {
        final path = await AndroidChannel.saveFile(
          bytes: bytes.toList(),
          fileName: fileName,
          directory: directory,
        );
        return path != null
            ? SaveResult.ok(path)
            : SaveResult.fail('Android: saveFile returned null');
      }

      if (PlatformInfo.isIOS) {
        final path = await IosChannel.saveFile(
          bytes: bytes.toList(),
          fileName: fileName,
          directory: directory,
        );
        return path != null
            ? SaveResult.ok(path)
            : SaveResult.fail('iOS: saveFile returned null');
      }

      if (PlatformInfo.isMacOS) {
        final path = await MacosChannel.saveFile(
          bytes: bytes.toList(),
          fileName: fileName,
          directory: directory,
        );
        return path != null
            ? SaveResult.ok(path)
            : SaveResult.fail('macOS: saveFile returned null');
      }

      if (PlatformInfo.isWindows) {
        return await WindowsSaver.saveFile(
          bytes: bytes,
          fileName: fileName,
          directory: directory,
        );
      }

      if (PlatformInfo.isLinux) {
        return await LinuxSaver.saveFile(
          bytes: bytes,
          fileName: fileName,
          directory: directory,
        );
      }

      return SaveResult.fail(
        'flutter_saver: unsupported platform ${PlatformInfo.operatingSystem}',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[flutter_saver] _dispatch error: $e');
      return SaveResult.fail(e.toString());
    }
  }

  /// Returns a file name, generating a random one when [name] is null/empty.
  static String _resolveName(String? name, String? fallbackExt) {
    if (name != null && name.isNotEmpty) return name;
    final base = generateRandomFileName();
    return fallbackExt != null ? '$base$fallbackExt' : base;
  }

  /// Builds a file name for an [XFile]: prefers [requested], then the XFile's
  /// own name/path, and finally falls back to a random name with a
  /// MIME-derived extension (camera photos are often unnamed blobs).
  static String _resolveXFileName(XFile file, String? requested) {
    if (requested != null && requested.isNotEmpty) return requested;

    // `file.name` is reliable on Web (real upload name); `file.path` on
    // native. Accept whichever actually carries an extension.
    for (final candidate in [file.name, p.basename(file.path)]) {
      if (candidate.isNotEmpty && p.extension(candidate).isNotEmpty) {
        return candidate;
      }
    }

    final ext = file.mimeType == null
        ? ''
        : extensionForMimeType(file.mimeType!);
    return ext.isNotEmpty
        ? '${generateRandomFileName()}$ext'
        : generateRandomFileName();
  }

  /// Builds a file name from the URL path, appending a MIME-derived extension
  /// if the URL itself carries no extension.
  static String _buildNameFromUrl(String link, String contentType) {
    final uri = Uri.tryParse(link);
    final segments = uri?.pathSegments ?? [];
    final lastName = segments.isNotEmpty ? segments.last : '';
    if (lastName.isNotEmpty && p.extension(lastName).isNotEmpty) {
      return lastName;
    }
    final base = lastName.isNotEmpty ? lastName : generateRandomFileName();
    final ext = extensionForMimeType(contentType);
    return ext.isNotEmpty ? '$base$ext' : base;
  }
}
