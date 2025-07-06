import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../providers/deck_provider.dart';
import 'card_view_screen.dart';

class StudyModeScreen extends StatefulWidget {
  final Deck deck;

  const StudyModeScreen({super.key, required this.deck});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  List<CardModel> _studyCards = [];
  int _currentCardIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudyCards();
  }

  Future<void> _loadStudyCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      final cards = await deckProvider.getCardsForDeck(widget.deck.id!);
      
      // Ordenar cartões por última visualização (mais antigos primeiro)
      cards.sort((a, b) {
        if (a.lastViewed == null && b.lastViewed == null) {
          return a.createdAt.compareTo(b.createdAt);
        }
        if (a.lastViewed == null) return -1;
        if (b.lastViewed == null) return 1;
        return a.lastViewed!.compareTo(b.lastViewed!);
      });

      setState(() {
        _studyCards = cards;
        _currentCardIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar cartões: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estudar: ${widget.deck.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudyCards,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studyCards.isEmpty
              ? _buildEmptyState()
              : _buildStudyInterface(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum cartão para estudar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione cartões ao baralho para começar a estudar.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Cartões'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyInterface() {
    final currentCard = _studyCards[_currentCardIndex];
    final progress = (_currentCardIndex + 1) / _studyCards.length;

    return Column(
      children: [
        // Barra de progresso
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cartão ${_currentCardIndex + 1} de ${_studyCards.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Cartão atual
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              child: InkWell(
                onTap: () => _viewCard(currentCard),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título do cartão
                      Text(
                        currentCard.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Preview do conteúdo
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            currentCard.content.isNotEmpty 
                                ? currentCard.content.length > 200
                                    ? '${currentCard.content.substring(0, 200)}...'
                                    : currentCard.content
                                : 'Nenhum conteúdo',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Indicadores de mídia
                      Row(
                        children: [
                          if (currentCard.hasDrawing) ...[
                            Container(
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
                            const SizedBox(width: 8),
                          ],
                          
                          if (currentCard.hasMedia) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.perm_media, size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text('Mídia', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          
                          const Spacer(),
                          
                          // Informações do cartão
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Visualizações: ${currentCard.viewCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (currentCard.lastViewed != null)
                                Text(
                                  'Última: ${_formatDate(currentCard.lastViewed!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botões de ação
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Botão anterior
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentCardIndex > 0 ? _previousCard : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Botão visualizar
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _viewCard(currentCard),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Visualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Botão próximo
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentCardIndex < _studyCards.length - 1 ? _nextCard : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Próximo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
      });
    }
  }

  void _nextCard() {
    if (_currentCardIndex < _studyCards.length - 1) {
      setState(() {
        _currentCardIndex++;
      });
    }
  }

  void _viewCard(CardModel card) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardViewScreen(
          card: card,
          isStudyMode: true,
        ),
      ),
    );

    // Se o cartão foi marcado como visualizado, recarregar a lista
    if (result == true || mounted) {
      await _loadStudyCards();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString().substring(2)}';
  }
}

