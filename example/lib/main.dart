import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_saver/flutter_saver.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_saver example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _log = 'Tap a button to test flutter_saver.';
  Uint8List? _photoBytes;

  // ── Save local bytes ──────────────────────────────────────────────────────

  Future<void> _saveLocalFile() async {
    final bytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);

    final result = await FlutterSaver.saveFile(
      bytes: bytes,
      fileName: 'test_file.bin',
      directory: SaveDirectory.downloads,
    );

    _showResult('saveFile', result);
  }

  // ── Take a photo with the camera and save it (XFile) ──────────────────────

  Future<void> _saveCameraPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return; // user cancelled the camera.

      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);

      final result = await FlutterSaver.saveXFile(
        picked,
        directory: SaveDirectory.pictures,
      );

      _showResult('saveXFile (camera)', result);
    } catch (e) {
      setState(() => _log = 'saveXFile (camera) ❌\nError: $e');
    }
  }

  // ── Download from network ─────────────────────────────────────────────────

  Future<void> _downloadNetworkFile() async {
    const url = 'https://swanflutterdev.com/test_image/test_1.jpg';

    final result = await FlutterSaver.downloadFile(
      link: url,
      fileName: '3123pacn7.jpg',
      directory: SaveDirectory.downloads,
    );

    _showResult('downloadFile', result);
  }

  /// Same code path — host sends `Access-Control-Allow-Origin: *`
  /// so the browser lets JS read the bytes → a real download happens.
  Future<void> _downloadNetworkFileCors() async {
    // picsum.photos is a public Lorem Ipsum image service with CORS enabled.
    // It is accessible without restrictions and suitable for testing.
    const url = 'https://picsum.photos/seed/flutter/640/480';

    final result = await FlutterSaver.downloadFile(
      link: url,
      fileName: 'picsum_test.jpg',
      directory: SaveDirectory.downloads,
    );

    _showResult('downloadFile (CORS host)', result);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showResult(String method, SaveResult result) {
    setState(() {
      if (result.success) {
        _log = '$method ✅\nPath: ${result.filePath ?? "(browser download)"}';
      } else {
        _log = '$method ❌\nError: ${result.error}';
        debugPrint('$method ❌\nError: ${result.error}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_saver example')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _saveLocalFile,
                child: const Text('Save local bytes → Downloads'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveCameraPhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Take photo with camera → Pictures'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _downloadNetworkFile,
                child: const Text('Download image (host WITHOUT CORS)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _downloadNetworkFileCors,
                child: const Text('Download image (host WITH CORS)'),
              ),
              const SizedBox(height: 24),
              if (_photoBytes != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_photoBytes!, fit: BoxFit.contain),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _log,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
