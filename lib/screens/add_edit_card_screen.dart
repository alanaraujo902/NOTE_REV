// lib/screens/add_edit_card_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/card_model.dart';
import '../database/database_helper.dart';
import '../services/image_service.dart';

// Model simples para traço — você pode aprimorar (cor, espessura, tempo...)
class Stroke {
  final List<Offset> points;
  Stroke(this.points);
  Map<String, dynamic> toMap() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };
  factory Stroke.fromMap(Map<String, dynamic> m) =>
      Stroke((m['points'] as List).map((p) => Offset(p['x'], p['y'])).toList());
}

class AddEditCardScreen extends StatefulWidget {
  final CardModel? card;
  const AddEditCardScreen({super.key, this.card});

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isDrawing = false;
  final List<Stroke> _strokes = [];
  List<Offset> _currentStroke = [];

  final DatabaseHelper _db = DatabaseHelper();
  final ImageService _img = ImageService();

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _titleController.text = widget.card!.title;
      _contentController.text = widget.card!.content;
      if (widget.card!.drawingPath != null) {
        final json = widget.card!.drawingPath!;
        final list = jsonDecode(json) as List;
        _strokes.addAll(list.map((e) => Stroke.fromMap(e)));
      }
    }
  }

  void _toggleDrawing() {
    setState(() => _isDrawing = !_isDrawing);
  }

  final GlobalKey _previewKey = GlobalKey();
  void _onPanStart(DragStartDetails d) {
    if (!_isDrawing) return;
    setState(() => _currentStroke = [d.localPosition]);
  }
  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isDrawing) return;
    setState(() => _currentStroke.add(d.localPosition));
  }
  void _onPanEnd(_) {
    if (!_isDrawing && _currentStroke.isEmpty) return;
    setState(() {
      _strokes.add(Stroke(List.from(_currentStroke)));
      _currentStroke = [];
    });
  }

  Future<void> _saveCard() async {
    final now = DateTime.now();
    final drawingJson = jsonEncode(_strokes.map((s) => s.toMap()).toList());

    String? snapshotPath;
    final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        snapshotPath = await _img.savePngFromBytes(pngBytes);
      }
    }

    final newCard = CardModel(
      id: widget.card?.id,
      title: _titleController.text,
      content: _contentController.text,
      imagePath: snapshotPath ?? widget.card?.imagePath,
      drawingPath: drawingJson,
      createdAt: widget.card?.createdAt ?? now,
      lastReviewed: widget.card?.lastReviewed ?? now,
      reviewCount: widget.card?.reviewCount ?? 0,
      position: widget.card?.position ?? -1,
    );

    if (widget.card != null) {
      await _db.updateCard(newCard);
    } else {
      await _db.insertCard(newCard);
    }

    if (mounted) Navigator.pop(context, true);
  }
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card != null ? 'Editar Card' : 'Novo Card'),
        actions: [
          IconButton(icon: Icon(_isDrawing ? Icons.close : Icons.draw), onPressed: _toggleDrawing),
          TextButton(onPressed: _saveCard, child: Text('Salvar')),
        ],
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: RepaintBoundary(
          key: _previewKey,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Título'),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(labelText: 'Conteúdo'),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isDrawing,
                  child: CustomPaint(
                    painter: _DrawingPainter(_strokes, _currentStroke),
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

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> current;
  _DrawingPainter(this.strokes, this.current);

  @override
  void paint(Canvas c, Size sz) {
    final p = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var s in strokes) {
      _drawStroke(c, p, s.points);
    }
    _drawStroke(c, p, current);
  }

  void _drawStroke(Canvas c, Paint p, List<Offset> pts) {
    if (pts.length < 2) return;
    for (int i = 0; i < pts.length - 1; i++) {
      c.drawLine(pts[i], pts[i+1], p);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter o) =>
      o.strokes != strokes || o.current != current;
}
