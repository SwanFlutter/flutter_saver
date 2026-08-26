## 2.2.0

* Migrates to built-in Kotlin: removes the `kotlin-android` plugin and replaces
  `kotlinOptions {}` with the `kotlin { compilerOptions {} }` DSL block,
  compatible with AGP 9+ and Flutter 3.44+.
* Fixes WASM compatibility: corrects the conditional import in
  `flutter_saver_base.dart` from `if (dart.library.io)` to
  `if (dart.library.js_interop)`, ensuring `dart:io` is never pulled into the
  Web/WASM import graph.
* Fixes Android `downloadFile` and `saveFile` not writing files on API 29+
  (Android 10 and above):
  - Sets `MediaStore.MediaColumns.MIME_TYPE` on every MediaStore insert so
    Android can properly index the file; without this, some devices (Samsung,
    Xiaomi, Oppo) silently reject the insert and return `null`.
  - Appends a trailing `/` to `RELATIVE_PATH` — required by certain OEM
    firmware builds.
  - Improves `openOutputStream` null-handling: deletes the orphaned MediaStore
    entry instead of leaking it.
* Fixes defensive `bytes` decoding in Kotlin: uses index-based `ByteArray`
  construction instead of `map`, preventing a rare crash on large files.
* Updates minimum supported SDK version to Flutter 3.44 / Dart 3.12.

---

## 2.1.1

* Fix WASM compatibility: detect Web via `dart.library.js_interop` instead of
  `dart.library.html` so the native `dart:io` branch is excluded from the
  Web/WASM import graph.

---

## 2.1.0

* Fix pub points.
* Make the package WASM/Web compatible by removing the top-level `dart:io`
  dependency (replaced with a conditional `PlatformInfo` abstraction).
* Fix `avoid_returning_futures_without_await` analysis warnings by awaiting
  dispatched platform futures.
* Remove the dead `resolveUniqueFilePath` helper and its unused `dart:io` import.

---


## 2.0.0

> **Breaking change** — full API redesign. See the Migration Guide in README.md.

### New features
- Unified `FlutterSaver.saveFile(bytes, fileName, directory)` — replaces all
  per-platform `saveImage*` methods.
- Unified `FlutterSaver.downloadFile(link, fileName, directory)` — replaces all
  per-platform `saveNetworkFile*` methods.
- New `SaveDirectory` enum (downloads, pictures, movies, dcim, documents, music,
  podcasts, ringtones, alarms, notifications, screenshots, audiobooks) used by
  both methods instead of separate `AndroidDirectory` / `DirectoryType` /
  `MacDirectoryType` enums.
- New `SaveResult` return type: `{ success, filePath, error }` — richer than the
  previous `bool` return.
- Platform detection is now fully internal — consumers never branch on platform.
- Full MIME → extension map (images, video, audio, documents) for automatic
  extension inference on network downloads.
- Android: native Kotlin plugin (`FlutterSaverPlugin.kt`) resolves real
  `Environment.DIRECTORY_*` paths without external dependencies.
- iOS: native Swift plugin saves to named sub-folders inside the app sandbox.
- macOS: native Swift plugin resolves real system directories via
  `FileManager.SearchPathDirectory`.
- Windows / Web: pure-Dart implementations (unchanged architecture, new API).
- Removed dependencies: `native_android_path`, `external_path_ios_mac`.
  Path logic is now built into the plugin's native code.
- Added `kotlin.incremental=false` to `android/gradle.properties` to fix
  cross-drive build failures on Windows (Pub Cache on C:\, project on another
  drive).

### Breaking changes
| Old method | New method |
|---|---|
| `saveImageAndroid(...)` | `FlutterSaver.saveFile(...)` |
| `saveImageIos(...)` | `FlutterSaver.saveFile(...)` |
| `saveImageMacOs(...)` | `FlutterSaver.saveFile(...)` |
| `saveImageWindowsWeb(...)` | `FlutterSaver.saveFile(...)` |
| `saveNetworkFileAndroid(...)` | `FlutterSaver.downloadFile(...)` |
| `saveNetworkFileIos(...)` | `FlutterSaver.downloadFile(...)` |
| `saveNetworkFileMac(...)` | `FlutterSaver.downloadFile(...)` |
| `saveNetworkFileWindowsWeb(...)` | `FlutterSaver.downloadFile(...)` |
| `AndroidDirectory.*` | `SaveDirectory.*` |
| `DirectoryType.*` | `SaveDirectory.*` |
| `MacDirectoryType.*` | `SaveDirectory.*` |
| Return type: `bool` | Return type: `SaveResult` |

### Build compatibility
- Requires Flutter ≥ 3.44.0 (AGP 9 support).
- Gradle plugin `build.gradle.kts` now uses conditional `apply(plugin = ...)` for
  KGP to remain compatible with both AGP 8 and AGP 9.

---

## 1.0.1

* Fix bug gradle

---

## 1.0.0
* Major stable release
* Add HTTP download support via `http` package
* Update `path_provider_master` to `^1.0.0` — fixes critical path resolution errors
* Update `native_android_path` to `^1.0.0` — fixes Android path errors
* Update `external_path_ios_mac` to `^0.0.8` — fixes iOS/macOS path errors

---

## 0.0.7
* Replace `path_provider` with `path_provider_master`
* Update downloads directory calls to `PathProviderMaster`

---

## 0.0.6
* Update SDK

---

## 0.0.5
* Fix bug

---

## 0.0.4
* Fix pub points
* Update SDK

---

## 0.0.3
* Fix pub points
* Update SDK

---

## 0.0.2
* Fix pub points
* Update SDK

---

## 0.0.1+7
* Fix pub points

---

## 0.0.1+6
* Update package

---

## 0.0.1+5
* Fix bug

---

## 0.0.1+4
* Refactor code
* Add audio & video formats to download file

---

## 0.0.1+3
* Fix bug

---

## 0.0.1+2
* Fix permission bug

---

## 0.0.1+1
* Fix platform support bug
* Add example file
* Fix pub points

---

## 0.0.1
* Initial release

---
