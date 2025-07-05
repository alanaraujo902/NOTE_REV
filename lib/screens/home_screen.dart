import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../database/database_helper.dart';
import '../widgets/card_widget.dart';
import 'add_edit_card_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  CardModel? _currentCard;
  int _totalCards = 0;
  int _currentPosition = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentCard();
  }

  Future<void> _loadCurrentCard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final card = await _databaseHelper.getNextCard();
      final totalCards = await _databaseHelper.getCardCount();

      setState(() {
        _currentCard = card;
        _totalCards = totalCards;
        _currentPosition = card != null ? card.position + 1 : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar card: $e')),
        );
      }
    }
  }

  Future<void> _markAsReviewed() async {
    if (_currentCard == null) return;

    try {
      await _databaseHelper.markCardAsReviewed(_currentCard!.id!);
      await _loadCurrentCard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card marcado como visto!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar card: $e')),
        );
      }
    }
  }

  Future<void> _addNewCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditCardScreen(),
      ),
    );

    if (result == true) {
      await _loadCurrentCard();
    }
  }

  Future<void> _editCurrentCard() async {
    if (_currentCard == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCardScreen(card: _currentCard),
      ),
    );

    if (result == true) {
      await _loadCurrentCard();
    }
  }

  Future<void> _deleteCurrentCard() async {
    if (_currentCard == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteCard(_currentCard!.id!);
        await _loadCurrentCard();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card excluído!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir card: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Deck'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentCard != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editCurrentCard,
              tooltip: 'Editar card',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCurrentCard,
              tooltip: 'Excluir card',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentCard == null
          ? _buildEmptyState()
          : _buildCardView(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentCard != null) ...[
            FloatingActionButton(
              heroTag: "reviewed",
              onPressed: _markAsReviewed,
              backgroundColor: Colors.green,
              child: const Icon(Icons.check),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: "add",
            onPressed: _addNewCard,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum card encontrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para adicionar seu primeiro card',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card $_currentPosition de $_totalCards',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Revisado ${_currentCard!.reviewCount} vezes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Card content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CardWidget(card: _currentCard!),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markAsReviewed,
                  icon: const Icon(Icons.check),
                  label: const Text('Visto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

