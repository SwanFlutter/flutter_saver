import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_saver/flutter_saver.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ValueNotifier<File?> _savedImageNotifier = ValueNotifier<File?>(null);
  String urlImage =
      "https://platinumlist.net/guide/wp-content/uploads/2023/03/IMG-worlds-of-adventure.webp";

  @override
  void dispose() {
    _savedImageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Unsplash Images"),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ValueListenableBuilder<File?>(
              valueListenable: _savedImageNotifier,
              builder: (context, savedImage, child) {
                if (savedImage != null) {
                  return Column(
                    children: [
                      Image.file(
                        savedImage,
                        width: 300,
                        height: 450,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return TextButton(
                  onPressed: () async {
                    final result = await FlutterSaver.saveFile(
                      link: urlImage,
                    );

                    if (result.state) {
                      _savedImageNotifier.value = result.file;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image saved successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save image.'),
                        ),
                      );
                    }
                  },
                  child: const Text("Download"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
