import 'package:flutter/material.dart';
import 'package:heracle/src/camera/domain/text_overlay.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;

class TextEditorWidget extends StatefulWidget {
  final Function(TextOverlay) onDone;
  final TextOverlay? initialOverlay; // <-- added

  const TextEditorWidget({super.key, required this.onDone, this.initialOverlay}); // <-- updated

  @override
  State<TextEditorWidget> createState() => _TextEditorWidgetState();
}

class _TextEditorWidgetState extends State<TextEditorWidget> {
  final TextEditingController _controller = TextEditingController();
  Color _selectedColor = Colors.white;
  TextStyle _selectedStyle = const TextStyle(fontSize: 30);
  int _selectedFontIndex = 0;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  final List<TextStyle> _fonts = [
    const TextStyle(fontSize: 30, fontFamily: 'Roboto'), // Classic
    const TextStyle(fontSize: 30, fontFamily: 'Cursive', fontStyle: FontStyle.italic), // Signature (approx)
    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold), // Editor (approx)
    const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2), // Poster (approx)
  ];

  final List<String> _fontNames = ["Classic", "Signature", "Editor", "Poster"];

  @override
  void initState() {
    super.initState();
    // If editing an existing overlay, prefill values
    if (widget.initialOverlay != null) {
      final it = widget.initialOverlay!;
      _controller.text = it.text;
      _selectedColor = it.color;
      _selectedStyle = it.style.copyWith(color: _selectedColor);
      // Try to detect font index by equality of style.family/weight roughly
      // best-effort mapping:
      for (var i = 0; i < _fonts.length; i++) {
        final f = _fonts[i];
        if (f.fontFamily == it.style.fontFamily &&
            f.fontWeight == it.style.fontWeight) {
          _selectedFontIndex = i;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer for alignment
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Align", style: TextStyle(color: Colors.white)),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_controller.text.isNotEmpty) {
                        final overlay = TextOverlay(
                          id: widget.initialOverlay?.id ?? const uuid_pkg.Uuid().v4(), // preserve id if editing
                          text: _controller.text,
                          color: _selectedColor,
                          style: _selectedStyle.copyWith(color: _selectedColor),
                          position: widget.initialOverlay?.position ?? Offset(
                            MediaQuery.of(context).size.width / 2 - 50,
                            MediaQuery.of(context).size.height / 2 - 50,
                          ),
                          scale: widget.initialOverlay?.scale ?? 1.0,
                          rotation: widget.initialOverlay?.rotation ?? 0.0,
                        );
                        widget.onDone(overlay);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Text Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textAlign: TextAlign.center,
                style: _selectedStyle.copyWith(color: _selectedColor),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),

            const Spacer(),

            // Font Selector
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _fonts.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFontIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFontIndex = index;
                        _selectedStyle = _fonts[index];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            )
                          : null,
                      child: Text(
                        _fontNames[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Color Selector
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : Border.all(color: Colors.white24, width: 1),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
