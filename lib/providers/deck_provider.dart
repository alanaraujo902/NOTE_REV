import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../database/database_helper.dart';

class DeckProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Deck> _decks = [];
  List<CardModel> _currentDeckCards = [];
  Deck? _selectedDeck;
  CardModel? _currentCard;
  bool _isLoading = false;

  // Getters
  List<Deck> get decks => _decks;
  List<CardModel> get currentDeckCards => _currentDeckCards;
  Deck? get selectedDeck => _selectedDeck;
  CardModel? get currentCard => _currentCard;
  bool get isLoading => _isLoading;

  // Inicializar provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadDecks();
    } catch (e) {
      debugPrint('Erro ao inicializar DeckProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // OPERAÇÕES COM BARALHOS

  Future<void> loadDecks() async {
    try {
      _decks = await _databaseHelper.getAllDecks();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar baralhos: $e');
    }
  }

  Future<void> createDeck(String title) async {
    try {
      final deck = Deck.create(title);
      final id = await _databaseHelper.insertDeck(deck);
      final newDeck = deck.copyWith(id: id);
      _decks.insert(0, newDeck);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao criar baralho: $e');
    }
  }

  Future<void> updateDeck(Deck deck) async {
    try {
      final updatedDeck = deck.copyWith(updatedAt: DateTime.now());
      await _databaseHelper.updateDeck(updatedDeck);

      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        _decks[index] = updatedDeck;
        if (_selectedDeck?.id == deck.id) {
          _selectedDeck = updatedDeck;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar baralho: $e');
    }
  }

  Future<void> deleteDeck(int deckId) async {
    try {
      await _databaseHelper.deleteDeck(deckId);
      _decks.removeWhere((deck) => deck.id == deckId);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = null;
        _currentDeckCards.clear();
        _currentCard = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao deletar baralho: $e');
    }
  }

  Future<void> selectDeck(Deck deck) async {
    try {
      _selectedDeck = deck;
      await loadCardsForDeck(deck.id!);
    } catch (e) {
      debugPrint('Erro ao selecionar baralho: $e');
    }
  }

  // OPERAÇÕES COM CARTÕES

  Future<void> loadCardsForDeck(int deckId) async {
    try {
      _currentDeckCards = await _databaseHelper.getCardsByDeckId(deckId);
      _currentCard = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar cartões: $e');
    }
  }

  Future<void> createCard({
    required String title,
    required int deckId,
    String content = '',
  }) async {
    try {
      final card = CardModel.create(
        title: title,
        deckId: deckId,
        content: content,
      );

      final id = await _databaseHelper.insertCard(card);
      final newCard = card.copyWith(id: id);

      if (_selectedDeck?.id == deckId) {
        _currentDeckCards.add(newCard);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao criar cartão: $e');
    }
  }

  Future<void> updateCard(CardModel card) async {
    try {
      final updatedCard = card.copyWith(updatedAt: DateTime.now());
      await _databaseHelper.updateCard(updatedCard);

      final index = _currentDeckCards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _currentDeckCards[index] = updatedCard;
        if (_currentCard?.id == card.id) {
          _currentCard = updatedCard;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar cartão: $e');
    }
  }

  Future<void> deleteCard(int cardId) async {
    try {
      await _databaseHelper.deleteCard(cardId);
      _currentDeckCards.removeWhere((card) => card.id == cardId);

      if (_currentCard?.id == cardId) {
        _currentCard = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao deletar cartão: $e');
    }
  }

  Future<void> markCardAsViewed(CardModel card) async {
    try {
      final viewedCard = card.markAsViewed();
      await updateCard(viewedCard);

      // Reordenar cartões para mostrar o próximo
      if (_selectedDeck != null) {
        await loadCardsForDeck(_selectedDeck!.id!);
      }
    } catch (e) {
      debugPrint('Erro ao marcar cartão como visualizado: $e');
    }
  }

  Future<CardModel?> getNextCardToView() async {
    if (_selectedDeck == null) return null;

    try {
      return await _databaseHelper.getNextCardToView(_selectedDeck!.id!);
    } catch (e) {
      debugPrint('Erro ao obter próximo cartão: $e');
      return null;
    }
  }

  void setCurrentCard(CardModel? card) {
    _currentCard = card;
    notifyListeners();
  }

  Future<Deck> getDefaultDeck() async {
    try {
      return await _databaseHelper.getDefaultDeck();
    } catch (e) {
      debugPrint('Erro ao obter baralho padrão: $e');
      rethrow;
    }
  }

  Future<int> getCardCount(int deckId) async {
    try {
      return await _databaseHelper.getCardCountByDeckId(deckId);
    } catch (e) {
      debugPrint('Erro ao contar cartões: $e');
      return 0;
    }
  }

  // Método corrigido movido para dentro da classe
  Future<List<CardModel>> getCardsForDeck(int deckId) async {
    try {
      final cards = await _databaseHelper.getCardsByDeckId(deckId);
      return cards;
    } catch (e) {
      print('Erro ao carregar cartões do baralho: $e');
      return [];
    }
  }
}
