import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onTextChanged;
  final bool showPreview;

  const MarkdownEditor({
    super.key,
    required this.initialText,
    required this.onTextChanged,
    this.showPreview = true,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _tabController = TabController(length: 2, vsync: this);
    _controller.addListener(() {
      widget.onTextChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de ferramentas
        _buildToolbar(),
        
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

  Widget _buildToolbar() {
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
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
  }

  Widget _buildPreview() {
    return Container(
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

