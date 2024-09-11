import 'dart:math';

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
