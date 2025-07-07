import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingCanvas extends StatefulWidget {
  final double width;
  final double height;
  final Function(Uint8List) onDrawingChanged;
  final Uint8List? initialDrawing;
  final bool isDrawingMode;

  const DrawingCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.onDrawingChanged,
    this.initialDrawing,
    this.isDrawingMode = true,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final GlobalKey _canvasKey = GlobalKey();
  List<DrawingPoint> _points = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;
  ui.Image? _backgroundImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawing != null) {
      _loadInitialDrawing();
    }
  }

  Future<void> _loadInitialDrawing() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.initialDrawing!);
      final frame = await codec.getNextFrame();
      setState(() {
        _backgroundImage = frame.image;
      });
    } catch (e) {
      debugPrint('Erro ao carregar desenho inicial: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de ferramentas de desenho
        if (widget.isDrawingMode) _buildDrawingToolbar(),

        // Canvas de desenho
        Expanded(
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RepaintBoundary(
                key: _canvasKey,
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: DrawingPainter(
                    points: _points,
                    backgroundImage: _backgroundImage,
                  ),
                  child: GestureDetector(
                    onPanStart: widget.isDrawingMode ? _onPanStart : null,
                    onPanUpdate: widget.isDrawingMode ? _onPanUpdate : null,
                    onPanEnd: widget.isDrawingMode ? _onPanEnd : null,
                    child: Container(
                      width: widget.width,
                      height: widget.height,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Seletor de cor
          _buildColorButton(Colors.black),
          _buildColorButton(Colors.red),
          _buildColorButton(Colors.blue),
          //_buildColorButton(Colors.green),
          //_buildColorButton(Colors.orange),
          //_buildColorButton(Colors.purple),

          const SizedBox(width: 1),

          // Seletor de espessura
          const Text('Espessura:'),
          const SizedBox(width: 1),
          SizedBox(
            width: 100,
            child: Slider(
              value: _strokeWidth,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _strokeWidth = value;
                });
              },
            ),
          ),
          Text('${_strokeWidth.toInt()}'),

          const Spacer(),

          // Botões de ação
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearDrawing,
            tooltip: 'Limpar desenho',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
            tooltip: 'Salvar desenho',
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.grey[800]! : Colors.grey[400]!,
            width: _selectedColor == color ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _points.add(DrawingPoint(
        offset: localPosition,
        paint: Paint()
          ..color = _selectedColor
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _points.add(DrawingPoint(
        offset: localPosition,
        paint: Paint()
          ..color = _selectedColor
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      ));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _points.add(DrawingPoint(offset: null, paint: Paint()));
    });
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
      _backgroundImage = null;
    });
    _saveDrawing();
  }

  Future<void> _saveDrawing() async {
    try {
      final RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        widget.onDrawingChanged(pngBytes);
      }
    } catch (e) {
      debugPrint('Erro ao salvar desenho: $e');
    }
  }
}

class DrawingPoint {
  final Offset? offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final ui.Image? backgroundImage;

  DrawingPainter({required this.points, this.backgroundImage});

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar imagem de fundo se existir
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }

    // Desenhar pontos
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

