import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:meme_editor_app/exportpage.dart';
import 'package:flutter/rendering.dart';

class DetailPage extends StatefulWidget {
  final Map meme;

  const DetailPage({Key? key, required this.meme}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<Widget> elements = []; // elemen aktif
  List<Widget> undoStack = [];
  List<Widget> redoStack = [];

  final GlobalKey previewKey = GlobalKey();

  void addText() {
    final newText = EditableDraggableText(
      key: UniqueKey(),
      initialText: "Teks Baru",
    );
    setState(() {
      elements.add(newText);
      undoStack.add(newText);
    });
  }

  void addSticker() {
    final newSticker = EditableSticker(key: UniqueKey());
    setState(() {
      elements.add(newSticker);
      undoStack.add(newSticker);
    });
  }

  void undo() {
    if (elements.isNotEmpty) {
      setState(() {
        final removed = elements.removeLast();
        redoStack.add(removed);
      });
    }
  }

  void redo() {
    if (redoStack.isNotEmpty) {
      setState(() {
        final restored = redoStack.removeLast();
        elements.add(restored);
      });
    }
  }

  void exportMeme() async {
    try {
      final boundary =
          previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExportPage(capturedImageBytes: pngBytes),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Gagal mengekspor gambar")));
      }
    } catch (e) {
      print("❌ Error exporting: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Terjadi kesalahan saat ekspor")),
      );
    }
  }

  // void exportMeme() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => ExportPage(
  //         contentToExport: RepaintBoundary(
  //           key: previewKey,
  //           child: Stack(
  //             children: [
  //               Center(child: Image.network(widget.meme['url'])),
  //               ...elements,
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meme['name']),
        actions: [
          IconButton(icon: Icon(Icons.undo), onPressed: undo),
          IconButton(icon: Icon(Icons.redo), onPressed: redo),
          IconButton(icon: Icon(Icons.text_fields), onPressed: addText),
          IconButton(icon: Icon(Icons.emoji_emotions), onPressed: addSticker),
          IconButton(icon: Icon(Icons.upload), onPressed: exportMeme),
        ],
      ),
      body: SafeArea(
        child: RepaintBoundary(
          key: previewKey,
          child: Stack(
            children: [
              Center(child: Image.network(widget.meme['url'])),
              ...elements,
            ],
          ),
        ),
      ),
    );
  }
}

class EditableDraggableText extends StatefulWidget {
  final String initialText;

  const EditableDraggableText({Key? key, required this.initialText})
    : super(key: key);

  @override
  _EditableDraggableTextState createState() => _EditableDraggableTextState();
}

class _EditableDraggableTextState extends State<EditableDraggableText> {
  Offset position = Offset(100, 100);
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DraggableElement extends StatefulWidget {
  final Widget child;

  const DraggableElement({Key? key, required this.child}) : super(key: key);

  @override
  _DraggableElementState createState() => _DraggableElementState();
}

class _DraggableElementState extends State<DraggableElement> {
  Offset position = Offset(100, 100);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        child: widget.child,
      ),
    );
  }
}

class EditableSticker extends StatefulWidget {
  const EditableSticker({Key? key}) : super(key: key);

  @override
  State<EditableSticker> createState() => _EditableStickerState();
}

class _EditableStickerState extends State<EditableSticker> {
  Offset position = Offset(100, 100);
  String emoji = "😎";

  void _chooseEmoji() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final emojis = ["😎", "😂", "🔥", "❤️", "🥺", "👍"];
        return GridView.count(
          crossAxisCount: 4,
          children: emojis.map((e) {
            return InkWell(
              onTap: () {
                Navigator.pop(context, e);
              },
              child: Center(child: Text(e, style: TextStyle(fontSize: 32))),
            );
          }).toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        emoji = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        onTap: _chooseEmoji,
        child: Text(emoji, style: TextStyle(fontSize: 40)),
      ),
    );
  }
}
