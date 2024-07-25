
A package to save image and files to downloads folder.

## Features

You can use this code to save images on any platform.


```dart
FlutterSaver.saveImageWindowsWeb();

```

-Example

```dart
 await FlutterSaver.saveImageWindowsWeb(
  fileImage: fileImage,
   fileName: 'example',
 type: 'jpg',
 );
```

You can use this code to save images on any platform.

```
```

-Example

```dart
 await FlutterSaver.saveFileAndroid(
  "link file",
  ExternalPath.getExternalStoragePublicDirectory(
     ExternalPath.DIRECTORY_DOWNLOADS
   )
 );
```

## Getting started

```yaml
dependencies:
  flutter_saver: ^0.0.6
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

## Additional information

If you have any issues, questions, or suggestions related to this package, please feel free to contact us at [swan.dev1993@gmail.com](mailto:swan.dev1993@gmail.com). We welcome your feedback and will do our best to address any problems or provide assistance.
For more information about this package, you can also visit our [GitHub repository](https://github.com/SwanFlutter/flutter_saver) where you can find additional resources, contribute to the package's development, and file issues or bug reports. We appreciate your contributions and feedback, and we aim to make this package as useful as possible for our users.
Thank you for using our package, and we look forward to hearing from you!
