import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportPage extends StatelessWidget {
  final Uint8List capturedImageBytes;

  const ExportPage({Key? key, required this.capturedImageBytes})
    : super(key: key);

  static const MethodChannel platform = MethodChannel('com.meme_editor/save');

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      final result = await platform.invokeMethod(
        'saveImage',
        capturedImageBytes,
      );
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Gambar berhasil disimpan ke galeri")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Gagal menyimpan gambar")));
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Platform Error: ${e.message}")),
      );
    }
  }

  Future<void> _shareImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}/meme_shared.png");
      await file.writeAsBytes(capturedImageBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Lihat meme editanku 😎🔥");
    } catch (e) {
      print("❌ Error saat membagikan gambar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Export Meme")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.memory(capturedImageBytes, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text("Simpan"),
                  onPressed: () => _saveToGallery(context),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text("Bagikan"),
                  onPressed: _shareImage,
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
