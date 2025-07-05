import 'dart:convert';
import 'package:flutter/material.dart';

class Stroke {
  final List<Offset> points;
  Stroke(this.points);

  factory Stroke.fromMap(Map<String, dynamic> map) {
    final points = (map['points'] as List)
        .map((p) => Offset(p['x'].toDouble(), p['y'].toDouble()))
        .toList();
    return Stroke(points);
  }

  Map<String, dynamic> toMap() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };
}

class DrawingWidget extends StatelessWidget {
  final String drawingJson;
  const DrawingWidget({super.key, required this.drawingJson});

  @override
  Widget build(BuildContext context) {
    final List decoded = jsonDecode(drawingJson);
    final List<Stroke> strokes =
    decoded.map((e) => Stroke.fromMap(e)).toList();

    // Calcula altura máxima dos traços para definir tamanho real
    double maxY = 0;
    for (final stroke in strokes) {
      for (final point in stroke.points) {
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    return SizedBox(
      height: maxY + 20, // adiciona margem de segurança
      width: double.infinity,
      child: CustomPaint(
        painter: _DrawingPainter(strokes),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var stroke in strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}