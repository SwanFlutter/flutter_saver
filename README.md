# flutter_saver

A cross-platform Flutter plugin for saving any file type — images, videos, PDFs,
audio, zip archives, and more — to device storage, and for downloading files from
a network URL.

One API, every platform. No per-platform branching in your code.

---

## Supported platforms

| Platform | Save local file | Download from network |
|---|---|---|
| Android | ✅ | ✅ |
| iOS | ✅ | ✅ |
| macOS | ✅ | ✅ |
| Windows | ✅ | ✅ |
| Linux | ✅ | ✅ |
| Web | ✅ (browser download) | ✅ (browser download) |

---

## Installation

```yaml
dependencies:
  flutter_saver: ^2.3.0
```

---

## Platform setup

### Android

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- Android 13+ (API 33) granular media permissions -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

<application
    ...
    android:requestLegacyExternalStorage="true"> <!-- Required for API 29 -->
```

**Note on API levels:**
- API 29 (Android 10): `requestLegacyExternalStorage="true"` is required.
- API 33+ (Android 13): Use the granular `READ_MEDIA_*` permissions instead of
  (or in addition to) the legacy `READ/WRITE_EXTERNAL_STORAGE` permissions.

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app saves files to your device.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app saves files to your Photos library.</string>
```

Files are saved as named sub-folders inside the app's sandbox `Documents/`
directory (e.g. `Documents/Pictures/`, `Documents/Downloads/`).

### macOS

Add to `macos/Runner/DebugProfile.entitlements` and
`macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.files.downloads.read-write</key>
<true/>
<key>com.apple.security.files.pictures.read-write</key>
<true/>
<key>com.apple.security.files.movies.read-write</key>
<true/>
```

macOS saves to real system folders (`~/Downloads`, `~/Pictures`, `~/Movies`,
`~/Documents`, `~/Music`). Directories without a native macOS equivalent
(dcim, podcasts, ringtones, etc.) fall back to `~/Downloads`.

### Windows

No extra setup required. Files are saved to the user's `Downloads` folder via
`SHGetKnownFolderPath` (Win32 Shell API). File writes happen on a background
thread and are marshalled back to the platform thread safely.
Other `SaveDirectory` values fall back to Downloads with a debug warning.

### Linux

No extra setup required. Directories are resolved via GLib's XDG user-dirs
(`g_get_user_special_dir`). Supported directories:

| SaveDirectory | XDG directory |
|---|---|
| downloads | `G_USER_DIRECTORY_DOWNLOAD` |
| pictures | `G_USER_DIRECTORY_PICTURES` |
| movies / videos | `G_USER_DIRECTORY_VIDEOS` |
| documents | `G_USER_DIRECTORY_DOCUMENTS` |
| music | `G_USER_DIRECTORY_MUSIC` |
| all others | → Downloads fallback |

### Web

No extra setup required. The browser handles the save dialog.
`SaveDirectory` is ignored on Web (the browser controls the location).

`downloadFile` on Web first fetches the URL and downloads the response as a
Blob — this works for **every** format (jpg, png, svg, mp4, mp3, pdf, zip, …)
and keeps your suggested file name, but it requires the remote host to allow
CORS (`Access-Control-Allow-Origin`). Browsers deliberately block reading
cross-origin bytes without it, and they also ignore the `download` attribute
on cross-origin links — no library can bypass this.

When the host blocks CORS, flutter_saver automatically re-fetches the file
through a **CORS proxy** so the download still happens. The proxies are
configurable:

```dart
// Override with your own proxy (recommended for production — privacy:
// public proxies see the fetched URLs), or set to [] to disable the
// fallback (non-CORS hosts then open in a new tab instead).
FlutterSaver.webCorsProxies = [
  'https://my-proxy.example.com/{rawUrl}', // {rawUrl} = plain URL
  // 'https://my-proxy.example.com/?url={url}', // {url} = encoded URL
];
```

To make a file directly downloadable from your own server (best option —
no proxy involved), serve it with:

```
Access-Control-Allow-Origin: *
Content-Disposition: attachment        # optional — forces download even on navigation
```

---

## Usage

```dart
import 'package:flutter_saver/flutter_saver.dart';
```

### Save a local file

```dart
final Uint8List bytes = /* your file bytes */;

final SaveResult result = await FlutterSaver.saveFile(
  bytes: bytes,
  fileName: 'my_photo.jpg',            // optional — random name if omitted
  directory: SaveDirectory.pictures,   // optional — defaults to downloads
);

if (result.success) {
  print('Saved to: ${result.filePath}');
} else {
  print('Error: ${result.error}');
}
```

### Save a camera photo / picked file (XFile)

Works with `image_picker` (camera & gallery) on every platform — the `XFile`
is read and pushed through the same unified save pipeline:

```dart
final XFile? photo = await ImagePicker().pickImage(
  source: ImageSource.camera,
);

if (photo != null) {
  final SaveResult result = await FlutterSaver.saveXFile(
    photo,
    directory: SaveDirectory.pictures,
  );
  print(result.success ? 'Saved: ${result.filePath}' : result.error);
}
```

The file name is taken from the `XFile` (name/path, or inferred from its
MIME type) unless you pass `fileName` explicitly.

### Download a file from the network

```dart
final SaveResult result = await FlutterSaver.downloadFile(
  link: 'https://example.com/document.pdf',
  fileName: 'document.pdf',            // optional — inferred from URL / Content-Type
  directory: SaveDirectory.documents,  // optional — defaults to downloads
);

if (result.success) {
  print('Downloaded to: ${result.filePath}');
}
```

---

## SaveDirectory values

| Value | Android | iOS (sandbox) | macOS | Windows | Web |
|---|---|---|---|---|---|
| `downloads` | `DOWNLOADS` | `Documents/Downloads/` | `~/Downloads` | `~/Downloads` | browser |
| `pictures` | `PICTURES` | `Documents/Pictures/` | `~/Pictures` | ⬇ Downloads | browser |
| `movies` | `MOVIES` | `Documents/Movies/` | `~/Movies` | ⬇ Downloads | browser |
| `dcim` | `DCIM` | `Documents/DCIM/` | ⬇ Pictures | ⬇ Downloads | browser |
| `documents` | `DOCUMENTS` | `Documents/Documents/` | `~/Documents` | ⬇ Downloads | browser |
| `music` | `MUSIC` | `Documents/Music/` | `~/Music` | ⬇ Downloads | browser |
| `podcasts` | ⬇ Music | `Documents/Podcasts/` | ⬇ Downloads | ⬇ Downloads | browser |
| `ringtones` | `RINGTONES` | `Documents/Ringtones/` | ⬇ Downloads | ⬇ Downloads | browser |
| `alarms` | `ALARMS` | `Documents/Alarms/` | ⬇ Downloads | ⬇ Downloads | browser |
| `notifications` | `NOTIFICATIONS` | `Documents/Notifications/` | ⬇ Downloads | ⬇ Downloads | browser |
| `screenshots` | ⬇ Pictures | `Documents/Screenshots/` | ⬇ Downloads | ⬇ Downloads | browser |
| `audiobooks` | ⬇ Music | `Documents/Audiobooks/` | ⬇ Downloads | ⬇ Downloads | browser |

⬇ = falls back to the indicated directory; debug warning is printed.

---

## SaveResult

```dart
class SaveResult {
  final bool success;
  final String? filePath;  // null on Web
  final String? error;     // non-null when success == false
}
```

---

## Supported MIME types → extensions (auto-detected on download)

Images: `jpg, png, gif, webp, svg, tiff, ico, bmp, psd, djvu, xbm`  
Video: `mp4, avi, mpeg, mov, wmv, flv, webm, ogv, mkv, 3gp, 3g2`  
Audio: `mp3, wav, ogg, flac, aac, m4a, opus, wma, aiff, mka`  
Documents: `pdf, zip, docx, xlsx, pptx, exe, dwg`

---

## Migration guide (v1 → v2)

| v1 method | v2 equivalent |
|---|---|
| `FlutterSaver.saveImageAndroid(data, name, dir)` | `FlutterSaver.saveFile(bytes: data, fileName: name, directory: dir)` |
| `FlutterSaver.saveImageIos(data, name, dir)` | `FlutterSaver.saveFile(bytes: data, fileName: name, directory: dir)` |
| `FlutterSaver.saveImageMacOs(data, name, dir)` | `FlutterSaver.saveFile(bytes: data, fileName: name, directory: dir)` |
| `FlutterSaver.saveImageWindowsWeb(data, name)` | `FlutterSaver.saveFile(bytes: data, fileName: name)` |
| `FlutterSaver.saveNetworkFileAndroid(link, name, dir)` | `FlutterSaver.downloadFile(link: link, fileName: name, directory: dir)` |
| `FlutterSaver.saveNetworkFileIos(link, name, dir)` | `FlutterSaver.downloadFile(link: link, fileName: name, directory: dir)` |
| `FlutterSaver.saveNetworkFileMac(link, name, dir)` | `FlutterSaver.downloadFile(link: link, fileName: name, directory: dir)` |
| `FlutterSaver.saveNetworkFileWindowsWeb(link, name)` | `FlutterSaver.downloadFile(link: link, fileName: name)` |
| `AndroidDirectory.downloads` | `SaveDirectory.downloads` |
| `DirectoryType.pictures` | `SaveDirectory.pictures` |
| `MacDirectoryType.movies` | `SaveDirectory.movies` |
| Return `bool` | Return `SaveResult` — check `result.success` |

---

## License

MIT
