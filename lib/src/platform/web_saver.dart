// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../enums/save_directory.dart';
import '../models/save_result.dart';
import '../utils/mime_type_map.dart';

/// Web implementation of flutter_saver.
///
/// Every download goes through `Blob` + `<a download>`:
///
/// * [saveFile] wraps the given bytes in a Blob and clicks a synthetic
///   anchor. Blob URLs are same-origin, so the `download` attribute is
///   always honored — the browser saves the file instead of previewing it,
///   for **every** format (jpg, png, svg, mp4, mp3, pdf, zip, …).
/// * [downloadFile] first `fetch`es the URL, then downloads the response
///   bytes as a Blob the same way. This also works for every format, but
///   it requires the remote host to allow CORS (`Access-Control-Allow-Origin`).
///   When the host blocks CORS (JS cannot read the bytes at all and browsers
///   ignore `download` on cross-origin links), the URL is re-fetched
///   through the configured CORS proxies — see `FlutterSaver.webCorsProxies`
///   — so a real download still happens; only when every proxy fails is
///   the link opened in a new tab where the user can save manually.
class WebSaver {
  WebSaver._();

  static Future<SaveResult> saveFile({
    required Uint8List bytes,
    required String fileName,
    required SaveDirectory directory,
  }) async {
    try {
      if (directory != SaveDirectory.downloads) {
        if (kDebugMode) {
          debugPrint(
            '[flutter_saver] Web: SaveDirectory.$directory is not supported '
            '— the browser always controls the save location.',
          );
        }
      }

      // `bytes.toJS` preserves the view's offset and length; `bytes.buffer`
      // would append neighbouring bytes when [bytes] is a slice of a larger
      // buffer (common for http response bodies).
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/octet-stream'),
      );
      _downloadBlob(blob, fileName);

      return const SaveResult.ok(null);
    } catch (e) {
      return SaveResult.fail(e.toString());
    }
  }

  static Future<SaveResult> downloadFile({
    required String link,
    required String fileName,
    required SaveDirectory directory,
    List<String>? corsProxies,
  }) async {
    try {
      // data: URLs never touch the network.
      if (link.startsWith('data:')) {
        return await _saveDataUrl(link, fileName);
      }

      // Preferred path: fetch → Blob → <a download>. Downloads every format
      // with the suggested name, but needs the host to allow CORS.
      web.Response? response;
      try {
        response = await web.window.fetch(link.toJS).toDart;
      } catch (_) {
        // CORS / network error — handled by the fallbacks below.
      }

      if (response != null) {
        if (!response.ok) {
          return SaveResult.fail(
            'HTTP ${response.status}: failed to download $link',
          );
        }

        final saved = await _saveResponse(
          response: response,
          requested: fileName,
          url: link,
        );
        if (saved) return const SaveResult.ok(null);
      }

      // Fallback 1: the host blocks CORS, so re-fetch the file through a
      // CORS proxy (a server that re-serves it with
      // `Access-Control-Allow-Origin: *`) and download the bytes as a Blob.
      for (final template in corsProxies ?? const <String>[]) {
        final proxied = template
            .replaceAll('{url}', Uri.encodeComponent(link))
            .replaceAll('{rawUrl}', link);
        try {
          final proxiedResponse = await _fetchWithTimeout(proxied);
          if (!proxiedResponse.ok) continue;
          final saved = await _saveResponse(
            response: proxiedResponse,
            requested: fileName,
            url: link,
          );
          if (saved) return const SaveResult.ok(null);
        } catch (_) {
          // Broken/unavailable proxy — try the next one.
        }
      }

      // Fallback 2: no proxy worked. Browsers ignore the `download`
      // attribute on cross-origin links, so JS cannot force the file onto
      // the download shelf — open it in a new tab (keeps the app alive) so
      // the user can save it manually.
      if (kDebugMode) {
        debugPrint(
          '[flutter_saver] Web: "$link" does not allow CORS and no CORS '
          'proxy could fetch it. Opening it in a new tab instead. Serve the '
          'file with "Access-Control-Allow-Origin: *" (or configure '
          'FlutterSaver.webCorsProxies with your own proxy) to enable '
          'direct downloads of every format.',
        );
      }
      _openInNewTab(link);
      return const SaveResult.ok(null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[flutter_saver] WebSaver.downloadFile error: $e');
      }
      return SaveResult.fail(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // internals
  // ─────────────────────────────────────────────────────────────────────────

  /// Reads [response] as a Blob and triggers the download.
  /// Returns `false` when the body is empty, so callers can fall through
  /// to their next fallback.
  static Future<bool> _saveResponse({
    required web.Response response,
    required String? requested,
    required String url,
  }) async {
    final blob = await response.blob().toDart;
    if (blob.size == 0) return false;
    final name = _resolveFileName(
      requested: requested,
      response: response,
      url: url,
    );
    _downloadBlob(_withType(blob, response), name);
    return true;
  }

  /// `fetch` with a hard timeout, so a hanging proxy cannot stall the
  /// download chain forever.
  static Future<web.Response> _fetchWithTimeout(
    String url, {
    Duration timeout = const Duration(seconds: 25),
  }) {
    final controller = web.AbortController();
    final timer = Timer(timeout, () => controller.abort());
    final init = web.RequestInit(method: 'GET');
    (init as JSObject).setProperty('signal'.toJS, controller.signal);
    return web.window.fetch(url.toJS, init).toDart.whenComplete(timer.cancel);
  }

  static Future<SaveResult> _saveDataUrl(
    String dataUrl,
    String fileName,
  ) async {
    final comma = dataUrl.indexOf(',');
    if (comma < 0) {
      return SaveResult.fail('Invalid data: URL');
    }
    final header = dataUrl.substring(5, comma); // between "data:" and ","
    final isBase64 = header.toLowerCase().endsWith(';base64');
    final mime = header.split(';').first;
    final payload = dataUrl.substring(comma + 1);

    final Uint8List bytes;
    try {
      if (isBase64) {
        bytes = base64Decode(payload.trim());
      } else {
        bytes = Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));
      }
    } catch (e) {
      return SaveResult.fail('Invalid data: URL payload: $e');
    }

    var name = fileName;
    if (!name.contains('.')) {
      final ext = extensionForMimeType(mime);
      name = '$name${ext.isNotEmpty ? ext : '.bin'}';
    }
    return saveFile(
      bytes: bytes,
      fileName: name,
      directory: SaveDirectory.downloads,
    );
  }

  static void _downloadBlob(web.Blob blob, String fileName) {
    final blobUrl = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = blobUrl
      ..download = fileName
      ..rel = 'noopener';
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    // Revoking immediately can abort the download in Firefox/Safari, so the
    // URL is kept alive for a while after the click.
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(blobUrl));
  }

  static void _openInNewTab(String url) {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..target = '_blank'
      ..rel = 'noopener noreferrer';
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
  }

  static String _resolveFileName({
    required String? requested,
    required web.Response response,
    required String url,
  }) {
    var name = (requested != null && requested.isNotEmpty)
        ? requested
        : _fileNameFromContentDisposition(
                response.headers.get('content-disposition'),
              ) ??
              _fileNameFromUrl(url);

    // URLs without an extension (e.g. "/photo?id=12") would otherwise be
    // saved without one, so derive it from the Content-Type.
    if (!name.contains('.')) {
      final contentType =
          response.headers.get('content-type')?.split(';').first.trim() ?? '';
      final ext = extensionForMimeType(contentType);
      if (ext.isNotEmpty) name = '$name$ext';
    }
    return name;
  }

  /// Re-wraps [blob] with the response's Content-Type when the blob carries
  /// none, so the browser labels the downloaded file correctly.
  static web.Blob _withType(web.Blob blob, web.Response response) {
    if (blob.type.isNotEmpty) return blob;
    final contentType =
        response.headers.get('content-type')?.split(';').first.trim() ?? '';
    return web.Blob(
      [blob].toJS,
      web.BlobPropertyBag(
        type: contentType.isNotEmpty ? contentType : 'application/octet-stream',
      ),
    );
  }

  static String _fileNameFromUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final segment = segments.isEmpty ? '' : segments.last;
      if (segment.contains('.')) {
        return Uri.decodeComponent(segment);
      }
    } catch (_) {
      /* ignore */
    }
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String? _fileNameFromContentDisposition(String? value) {
    if (value == null) return null;
    // filename*=UTF-8''my%20video.mp4  (RFC 5987) has priority
    final ext = RegExp(
      r"filename\*=([^']*)''([^;]+)",
      caseSensitive: false,
    ).firstMatch(value);
    if (ext != null) {
      try {
        return Uri.decodeComponent(ext.group(2)!.trim());
      } catch (_) {
        /* ignore */
      }
    }
    final plain = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(value);
    return plain?.group(1)?.trim();
  }
}
