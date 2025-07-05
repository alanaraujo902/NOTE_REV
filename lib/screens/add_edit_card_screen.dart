import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/card_model.dart';
import '../database/database_helper.dart';
import '../services/image_service.dart';

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
  final GlobalKey _previewKey = GlobalKey();

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

  Future<void> _insertImageTag() async {
    final imagePath = await _img.pickImage();
    if (imagePath != null) {
      final cursorPos = _contentController.selection.baseOffset;
      final tag = '\n[IMAGE:$imagePath]\n';
      final text = _contentController.text;
      final idx = cursorPos >= 0 ? cursorPos : text.length;
      final newText = text.replaceRange(idx, idx, tag);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: idx + tag.length,
      );
      setState(() {});
    }
  }

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
        snapshotPath = await _img.savePngFromBytes(byteData.buffer.asUint8List());
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

    if (widget.card != null) await _db.updateCard(newCard);
    else await _db.insertCard(newCard);
    if (mounted) Navigator.pop(context, true);
  }

  List<Widget> _buildContentWidgets(String content) {
    final widgets = <Widget>[];
    final regex = RegExp(r'\[IMAGE:(.*?)\]');
    final parts = content.split(regex);
    final matches = regex.allMatches(content).toList();

    for (int i = 0; i < parts.length; i++) {
      final text = parts[i].trim();
      if (text.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ));
      }

      if (i < matches.length) {
        final imagePath = matches[i].group(1);
        if (imagePath != null && File(imagePath).existsSync()) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ));
        }
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card != null ? 'Editar Card' : 'Novo Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Inserir Imagem',
            onPressed: _insertImageTag,
          ),
          IconButton(
            icon: Icon(_isDrawing ? Icons.close : Icons.draw),
            tooltip: 'Modo Desenho',
            onPressed: _toggleDrawing,
          ),
          TextButton(onPressed: _saveCard, child: const Text('Salvar')),
        ],
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            RepaintBoundary(
              key: _previewKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isDrawing || !_contentController.text.contains('[IMAGE:'))
                                      TextField(
                                        controller: _contentController,
                                        maxLines: null,
                                        decoration: const InputDecoration(labelText: 'Conteúdo'),
                                        onChanged: (_) => setState(() {}),
                                      )
                                    else
                                      ..._buildContentWidgets(_contentController.text),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                ],
              ),
            ),
            IgnorePointer(
              ignoring: !_isDrawing,
              child: Positioned.fill(
                child: CustomPaint(
                  painter: _DrawingPainter(_strokes, _isDrawing ? _currentStroke : []),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Stroke {
  final List<Offset> points;
  Stroke(this.points);
  Map<String, dynamic> toMap() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };
  factory Stroke.fromMap(Map<String, dynamic> m) =>
      Stroke((m['points'] as List).map((p) => Offset(p['x'], p['y'])).toList());
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
      _draw(c, p, s.points);
    }
    _draw(c, p, current);
  }

  void _draw(Canvas c, Paint p, List<Offset> pts) {
    if (pts.length < 2) return;
    for (var i = 0; i < pts.length - 1; i++) {
      c.drawLine(pts[i], pts[i + 1], p);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter o) =>
      o.strokes != strokes || o.current != current;
}
