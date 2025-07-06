import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'drawing_canvas.dart';
import 'media_manager.dart';

enum EditorMode { text, drawing, media }

class EnhancedMarkdownEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onTextChanged;
  final Function(Uint8List?) onDrawingChanged;
  final Function(String?) onImageChanged;
  final Function(String?) onAudioChanged;
  final Uint8List? initialDrawing;
  final String? initialImagePath;
  final String? initialAudioPath;
  final bool showPreview;

  const EnhancedMarkdownEditor({
    super.key,
    required this.initialText,
    required this.onTextChanged,
    required this.onDrawingChanged,
    required this.onImageChanged,
    required this.onAudioChanged,
    this.initialDrawing,
    this.initialImagePath,
    this.initialAudioPath,
    this.showPreview = true,
  });

  @override
  State<EnhancedMarkdownEditor> createState() => _EnhancedMarkdownEditorState();
}

class _EnhancedMarkdownEditorState extends State<EnhancedMarkdownEditor>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late TabController _tabController;
  late ScrollController _scrollController;
  EditorMode _currentMode = EditorMode.text;
  Uint8List? _currentDrawing;
  String? _currentImagePath;
  String? _currentAudioPath;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _currentDrawing = widget.initialDrawing;
    _currentImagePath = widget.initialImagePath;
    _currentAudioPath = widget.initialAudioPath;
    
    _controller.addListener(() {
      widget.onTextChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de ferramentas principal
        _buildMainToolbar(),
        
        // Barra de ferramentas de texto (apenas no modo texto)
        if (_currentMode == EditorMode.text) _buildTextToolbar(),
        
        // Abas Editor/Preview
        if (widget.showPreview) _buildTabBar(),
        
        // Conteúdo
        Expanded(
          child: widget.showPreview
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEditor(),
                    _buildPreview(),
                  ],
                )
              : _buildEditor(),
        ),
      ],
    );
  }

  Widget _buildMainToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Seletor de modo
          SegmentedButton<EditorMode>(
            segments: const [
              ButtonSegment<EditorMode>(
                value: EditorMode.text,
                label: Text('Texto'),
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment<EditorMode>(
                value: EditorMode.drawing,
                label: Text('Desenho'),
                icon: Icon(Icons.brush),
              ),
              ButtonSegment<EditorMode>(
                value: EditorMode.media,
                label: Text('Mídia'),
                icon: Icon(Icons.perm_media),
              ),
            ],
            selected: {_currentMode},
            onSelectionChanged: (Set<EditorMode> newSelection) {
              setState(() {
                _currentMode = newSelection.first;
              });
            },
          ),
          
          const Spacer(),
          
          // Indicadores de mídia
          if (_currentDrawing != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.brush, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text('Desenho', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                ],
              ),
            ),
          
          if (_currentImagePath != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text('Imagem', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                ],
              ),
            ),
          
          if (_currentAudioPath != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.audiotrack, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text('Áudio', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Negrito',
              onPressed: () => _insertMarkdown('**', '**'),
            ),
            _buildToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Itálico',
              onPressed: () => _insertMarkdown('*', '*'),
            ),
            _buildToolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Riscado',
              onPressed: () => _insertMarkdown('~~', '~~'),
            ),
            const VerticalDivider(),
            _buildToolbarButton(
              icon: Icons.title,
              tooltip: 'Título 1',
              onPressed: () => _insertLineMarkdown('# '),
            ),
            _buildToolbarButton(
              icon: Icons.title,
              tooltip: 'Título 2',
              onPressed: () => _insertLineMarkdown('## '),
            ),
            _buildToolbarButton(
              icon: Icons.title,
              tooltip: 'Título 3',
              onPressed: () => _insertLineMarkdown('### '),
            ),
            const VerticalDivider(),
            _buildToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Lista',
              onPressed: () => _insertLineMarkdown('- '),
            ),
            _buildToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Lista numerada',
              onPressed: () => _insertLineMarkdown('1. '),
            ),
            _buildToolbarButton(
              icon: Icons.format_quote,
              tooltip: 'Citação',
              onPressed: () => _insertLineMarkdown('> '),
            ),
            const VerticalDivider(),
            _buildToolbarButton(
              icon: Icons.code,
              tooltip: 'Código inline',
              onPressed: () => _insertMarkdown('`', '`'),
            ),
            _buildToolbarButton(
              icon: Icons.code_off,
              tooltip: 'Bloco de código',
              onPressed: () => _insertMarkdown('```\n', '\n```'),
            ),
            _buildToolbarButton(
              icon: Icons.link,
              tooltip: 'Link',
              onPressed: () => _insertMarkdown('[texto](', ')'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(4),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Editor'),
          Tab(text: 'Preview'),
        ],
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildEditor() {
    switch (_currentMode) {
      case EditorMode.text:
        return Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            scrollController: _scrollController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'Digite seu conteúdo em Markdown...',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        );
      
      case EditorMode.drawing:
        return DrawingCanvas(
          width: double.infinity,
          height: double.infinity,
          onDrawingChanged: (drawing) {
            setState(() {
              _currentDrawing = drawing;
            });
            widget.onDrawingChanged(drawing);
          },
          initialDrawing: _currentDrawing,
          isDrawingMode: true,
        );
      
      case EditorMode.media:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MediaManager(
            initialImagePath: _currentImagePath,
            initialAudioPath: _currentAudioPath,
            onImageChanged: (imagePath) {
              setState(() {
                _currentImagePath = imagePath;
              });
              widget.onImageChanged(imagePath);
            },
            onAudioChanged: (audioPath) {
              setState(() {
                _currentAudioPath = audioPath;
              });
              widget.onAudioChanged(audioPath);
            },
          ),
        );
    }
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        // Preview do Markdown
        Container(
          padding: const EdgeInsets.all(16),
          child: Markdown(
            data: _controller.text.isEmpty ? '*Nenhum conteúdo para visualizar*' : _controller.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              p: const TextStyle(fontSize: 14, height: 1.5),
              code: TextStyle(
                backgroundColor: Colors.grey[200],
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
        
        // Overlay do desenho
        if (_currentDrawing != null)
          Positioned.fill(
            child: Image.memory(
              _currentDrawing!,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }

  void _insertMarkdown(String before, String after) {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$before$selectedText$after',
      );
      
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length + after.length,
      );
    } else {
      final cursorPos = _controller.selection.baseOffset;
      final newText = text.replaceRange(
        cursorPos,
        cursorPos,
        '$before$after',
      );
      
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: cursorPos + before.length,
      );
    }
  }

  void _insertLineMarkdown(String prefix) {
    final selection = _controller.selection;
    final text = _controller.text;
    final cursorPos = selection.baseOffset;
    
    // Encontrar o início da linha atual
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    // Inserir o prefixo no início da linha
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: cursorPos + prefix.length,
    );
  }
}

