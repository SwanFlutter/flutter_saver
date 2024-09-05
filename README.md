
This Flutter package provides a powerful and versatile solution for saving camera images and downloadable links across all platforms. With support for various formats, it allows developers to store images and files efficiently in device memory.

## Features

- You can use this code to save images on any platform.

- use for local image

```dart
FlutterSaver.saveImageWindowsWeb(fileImage: fileImage);
FlutterSaver.saveImageAndroid(fileImage: fileImage);
FlutterSaver.saveImageIos(fileImage: fileImage);
FlutterSaver.saveImageMacOs(fileImage: fileImage);

```

-Example

```dart
 await FlutterSaver.saveImageWindowsWeb(
  fileImage: fileImage,
   fileName: 'example',
 type: 'jpg',
 );
```

- You can use this code to save images on any platform.

- use for Network

```dart
 FlutterSaver.saveFileWindowsWeb(link: link);
 FlutterSaver.saveFileAndroid(link: link);
 FlutterSaver.saveFileIos(link: link);
 FlutterSaver.saveFileMac(link: link);
```

-Example

```dart
  GestureDetector(
              onTap: () async {
                Future<bool> isSaved = FlutterSaver.saveFileAndroid(
                    link:
                        "https://platinumlist.net/guide/wp-content/uploads/2023/03/IMG-worlds-of-adventure.webp");

                if (await isSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image saved successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save image.')),
                  );
                }
              },
       child: Image.network(
       width: 300,
        height: 450,
     "https://platinumlist.net/guide/wp-content/uploads/2023/03/IMG-worlds-of-adventure.webp"),
   ),
```

- suport this format

```dart
{
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
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
            '.xlsx',
        '.dwg': '.dwg',
      };
```

## Getting started

```yaml
dependencies:
  flutter_saver: ^0.0.1
```

```yaml
  dependencies:
 flutter_saver:
      git:
        url: https://github.com/SwanFlutter/flutter_saver.git
```

## How to use

```dart

import 'package:flutter_saver/flutter_saver.dart';

```


- To request permissions from the user, you can use the following code: AndroidManifest.xml.

```xml

<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

```

- Add this line code to application AndroidManifest.xml

```xml
android:requestLegacyExternalStorage="true"
```

```xml
<application
        android:label="avaterbetter"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
```

### iOS

```xml
     <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photo library to select images for editing.</string>
    <key>NSCameraUsageDescription</key>
    <string>We need access to your camera to take photos for editing.</string>
```

#### macOS installation

Since the macOS implementation uses `file_selector`, you will need to
add a filesystem access
[entitlement](https://docs.flutter.dev/platform-integration/macos/building#entitlements-and-the-app-sandbox):
```xml
  <key>com.apple.security.files.user-selected.read-only</key>
  <true/>
```

## Additional information

If you have any issues, questions, or suggestions related to this package, please feel free to contact us at [swan.dev1993@gmail.com](mailto:swan.dev1993@gmail.com). We welcome your feedback and will do our best to address any problems or provide assistance.
For more information about this package, you can also visit our [GitHub repository](https://github.com/SwanFlutter/flutter_saver) where you can find additional resources, contribute to the package's development, and file issues or bug reports. We appreciate your contributions and feedback, and we aim to make this package as useful as possible for our users.
Thank you for using our package, and we look forward to hearing from you!
