import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../providers/deck_provider.dart';
import '../widgets/card_tile.dart';
import 'card_edit_screen.dart';
import 'card_view_screen.dart';
import 'study_mode_screen.dart';

class DeckViewScreen extends StatefulWidget {
  final Deck deck;

  const DeckViewScreen({super.key, required this.deck});

  @override
  State<DeckViewScreen> createState() => _DeckViewScreenState();
}

class _DeckViewScreenState extends State<DeckViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      deckProvider.selectDeck(widget.deck);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _startStudySession,
            tooltip: 'Iniciar sessão de estudo',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createCard,
            tooltip: 'Criar novo cartão',
          ),
        ],
      ),
      body: Consumer<DeckProvider>(
        builder: (context, deckProvider, child) {
          if (deckProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cards = deckProvider.currentDeckCards;

          if (cards.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCardsList(cards);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCard,
        tooltip: 'Criar novo cartão',
        child: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum cartão encontrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro cartão para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createCard,
            icon: const Icon(Icons.add),
            label: const Text('Criar Cartão'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(List<CardModel> cards) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return CardTile(
          card: card,
          onTap: () => _viewCard(card),
          onEdit: () => _editCard(card),
          onDelete: () => _deleteCard(card),
        );
      },
    );
  }

  void _createCard() async {
    final title = await _showCardTitleDialog();
    if (title != null && title.isNotEmpty) {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      await deckProvider.createCard(
        title: title,
        deckId: widget.deck.id!,
      );
    }
  }

  Future<String?> _showCardTitleDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Cartão'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Título do cartão',
            hintText: 'Digite o título...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _viewCard(CardModel card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardViewScreen(card: card),
      ),
    );
  }

  void _editCard(CardModel card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardEditScreen(card: card),
      ),
    );
  }

  void _deleteCard(CardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o cartão "${card.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      await deckProvider.deleteCard(card.id!);
    }
  }

  void _startStudySession() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudyModeScreen(deck: widget.deck),
      ),
    );
  }
}

