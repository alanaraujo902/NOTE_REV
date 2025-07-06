import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card.dart';
import '../providers/deck_provider.dart';
import '../widgets/enhanced_markdown_editor.dart';

class CardEditScreen extends StatefulWidget {
  final CardModel card;

  const CardEditScreen({super.key, required this.card});

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  late TextEditingController _titleController;
  late String _content;
  Uint8List? _currentDrawing;
  String? _currentImagePath;
  String? _currentAudioPath;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _content = widget.card.content;
    _currentImagePath = widget.card.imagePath;
    _currentAudioPath = widget.card.audioPath;
    
    _titleController.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
      });
    });
    
    _loadExistingDrawing();
  }

  Future<void> _loadExistingDrawing() async {
    if (widget.card.drawingPath != null) {
      try {
        final file = File(widget.card.drawingPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          setState(() {
            _currentDrawing = bytes;
          });
        }
      } catch (e) {
        debugPrint('Erro ao carregar desenho existente: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Cartão'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                onPressed: _isLoading ? null : _saveCard,
                icon: const Icon(Icons.save),
                tooltip: 'Salvar',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Campo de título
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Editor avançado com desenho e mídia
                  Expanded(
                    child: EnhancedMarkdownEditor(
                      initialText: _content,
                      initialDrawing: _currentDrawing,
                      initialImagePath: widget.card.imagePath,
                      initialAudioPath: widget.card.audioPath,
                      onTextChanged: (text) {
                        setState(() {
                          _content = text;
                          _hasUnsavedChanges = true;
                        });
                      },
                      onDrawingChanged: (drawing) {
                        setState(() {
                          _currentDrawing = drawing;
                          _hasUnsavedChanges = true;
                        });
                      },
                      onImageChanged: (imagePath) {
                        setState(() {
                          _currentImagePath = imagePath;
                          _hasUnsavedChanges = true;
                        });
                      },
                      onAudioChanged: (audioPath) {
                        setState(() {
                          _currentAudioPath = audioPath;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: _hasUnsavedChanges
            ? FloatingActionButton(
                onPressed: _isLoading ? null : _saveCard,
                tooltip: 'Salvar',
                child: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text('Você tem alterações não salvas. Deseja sair sem salvar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair sem salvar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await _saveCard();
            },
            child: const Text('Salvar e sair'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<String?> _saveDrawingToFile(Uint8List drawingData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final drawingsDir = Directory('${directory.path}/drawings');
      if (!await drawingsDir.exists()) {
        await drawingsDir.create(recursive: true);
      }
      
      final fileName = 'drawing_${widget.card.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${drawingsDir.path}/$fileName');
      await file.writeAsBytes(drawingData);
      
      return file.path;
    } catch (e) {
      debugPrint('Erro ao salvar desenho: $e');
      return null;
    }
  }

  Future<void> _saveCard() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite um título para o cartão'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? drawingPath = widget.card.drawingPath;
      
      // Salvar desenho se existir
      if (_currentDrawing != null) {
        drawingPath = await _saveDrawingToFile(_currentDrawing!);
      } else if (widget.card.drawingPath != null) {
        // Remover desenho anterior se foi limpo
        try {
          final oldFile = File(widget.card.drawingPath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          debugPrint('Erro ao remover desenho anterior: $e');
        }
        drawingPath = null;
      }

      final updatedCard = widget.card.copyWith(
        title: title,
        content: _content,
        drawingPath: drawingPath,
        imagePath: _currentImagePath,
        audioPath: _currentAudioPath,
      );

      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      await deckProvider.updateCard(updatedCard);

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartão salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar cartão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

