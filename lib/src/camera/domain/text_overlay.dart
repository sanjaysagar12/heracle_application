import 'package:flutter/material.dart';

class TextOverlay {
  String id;
  String text;
  Offset position;
  double scale;
  double rotation;
  Color color;
  TextStyle style;

  TextOverlay({
    required this.id,
    required this.text,
    this.position = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
    this.style = const TextStyle(fontSize: 30),
  });
}
