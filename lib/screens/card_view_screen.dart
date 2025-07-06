import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/card.dart';
import '../providers/deck_provider.dart';
import 'card_edit_screen.dart';

class CardViewScreen extends StatelessWidget {
  final CardModel card;
  final bool isStudyMode;

  const CardViewScreen({
    super.key,
    required this.card,
    this.isStudyMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCard(context),
            tooltip: 'Editar cartão',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do cartão
            Text(
              card.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Conteúdo do cartão com desenho sobreposto
            _buildContentWithDrawing(context),
            
            const SizedBox(height: 16),
            
            // Informações do cartão
            _buildCardInfo(context),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            if (isStudyMode) _buildStudyModeActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContentWithDrawing(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Conteúdo em Markdown
            if (card.content.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: card.content,
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
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Text(
                  'Nenhum conteúdo adicionado ainda.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            // Desenho sobreposto
            if (card.drawingPath != null) _buildDrawingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingOverlay() {
    return Positioned.fill(
      child: FutureBuilder<bool>(
        future: _checkDrawingExists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              File(card.drawingPath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                      'Erro ao carregar desenho',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<bool> _checkDrawingExists() async {
    if (card.drawingPath == null) return false;
    try {
      final file = File(card.drawingPath!);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Widget _buildCardInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Visualizações:', '${card.viewCount}'),
            _buildInfoRow('Criado em:', _formatDateTime(card.createdAt)),
            _buildInfoRow('Atualizado em:', _formatDateTime(card.updatedAt)),
            if (card.lastViewed != null)
              _buildInfoRow('Última visualização:', _formatDateTime(card.lastViewed!)),
            if (card.hasMedia)
              _buildInfoRow('Mídia:', 'Sim'),
            if (card.hasDrawing)
              _buildInfoRow('Desenho:', 'Sim'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyModeActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markAsViewed(context),
            icon: const Icon(Icons.check),
            label: const Text('Visualizado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _editCard(context),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Cartão'),
          ),
        ),
      ],
    );
  }

  void _editCard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardEditScreen(card: card),
      ),
    );
  }

  void _markAsViewed(BuildContext context) async {
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);
    await deckProvider.markCardAsViewed(card);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cartão marcado como visualizado!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Se estiver em modo de estudo, voltar para a tela anterior
      if (isStudyMode) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

