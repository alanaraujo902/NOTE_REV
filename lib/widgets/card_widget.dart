import 'dart:io';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'drawing_widget.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;

  const CardWidget({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título removido para modo de revisão

            // Imagem com scroll e zoom
            Expanded(
              child: card.imagePath != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Image.file(
                      File(card.imagePath!),
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text("Erro ao carregar imagem"),
                      ),
                    ),
                  ),
                ),
              )
                  : const Center(child: Text("Sem imagem gerada")),
            ),

            const SizedBox(height: 16),
            _buildMetadata(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criado em: ${_formatDate(card.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Última revisão: ${_formatDate(card.lastReviewed)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${card.reviewCount} revisões',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
