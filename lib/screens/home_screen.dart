import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import '../widgets/deck_card.dart';
import '../widgets/create_deck_dialog.dart';
import 'deck_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Baralhos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDeckDialog(context),
            tooltip: 'Criar novo baralho',
          ),
        ],
      ),
      body: Consumer<DeckProvider>(
        builder: (context, deckProvider, child) {
          if (deckProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (deckProvider.decks.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildDecksList(context, deckProvider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCardDialog(context),
        tooltip: 'Criar novo cartão',
        child: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum baralho encontrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro baralho para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDeckDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Criar Baralho'),
          ),
        ],
      ),
    );
  }

  Widget _buildDecksList(BuildContext context, DeckProvider deckProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: deckProvider.decks.length,
        itemBuilder: (context, index) {
          final deck = deckProvider.decks[index];
          return DeckCard(
            deck: deck,
            onTap: () => _openDeck(context, deck),
            onEdit: () => _editDeck(context, deck),
            onDelete: () => _deleteDeck(context, deck),
          );
        },
      ),
    );
  }

  void _showCreateDeckDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateDeckDialog(),
    );
  }

  void _showCreateCardDialog(BuildContext context) async {
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);
    
    if (deckProvider.decks.isEmpty) {
      // Criar baralho padrão se não existir nenhum
      await deckProvider.createDeck('Baralho sem título');
    }

    if (!context.mounted) return;

    final selectedDeck = await showDialog<Deck>(
      context: context,
      builder: (context) => _buildDeckSelectionDialog(context, deckProvider.decks),
    );

    if (selectedDeck != null && context.mounted) {
      final title = await _showCardTitleDialog(context);
      if (title != null && title.isNotEmpty) {
        await deckProvider.createCard(
          title: title,
          deckId: selectedDeck.id!,
        );
      }
    }
  }

  Widget _buildDeckSelectionDialog(BuildContext context, List<Deck> decks) {
    return AlertDialog(
      title: const Text('Selecionar Baralho'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return ListTile(
              title: Text(deck.title),
              onTap: () => Navigator.of(context).pop(deck),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Future<String?> _showCardTitleDialog(BuildContext context) {
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

  void _openDeck(BuildContext context, Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeckViewScreen(deck: deck),
      ),
    );
  }

  void _editDeck(BuildContext context, Deck deck) async {
    final controller = TextEditingController(text: deck.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Baralho'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Título do baralho',
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      await deckProvider.updateDeck(deck.copyWith(title: newTitle));
    }
  }

  void _deleteDeck(BuildContext context, Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o baralho "${deck.title}"?\n\nTodos os cartões serão perdidos.'),
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

    if (confirmed == true && context.mounted) {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      await deckProvider.deleteDeck(deck.id!);
    }
  }
}

