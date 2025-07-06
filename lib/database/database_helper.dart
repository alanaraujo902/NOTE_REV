import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/deck.dart';
import '../models/card.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'card_deck_app.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Criar tabela de baralhos
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Criar tabela de cartões
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        deck_id INTEGER NOT NULL,
        image_path TEXT,
        audio_path TEXT,
        drawing_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_viewed INTEGER,
        view_count INTEGER DEFAULT 0,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // Criar baralho padrão
    await db.insert('decks', {
      'title': 'Baralho sem título',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // OPERAÇÕES COM BARALHOS

  Future<int> insertDeck(Deck deck) async {
    final db = await database;
    return await db.insert('decks', deck.toMap());
  }

  Future<List<Deck>> getAllDecks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Deck.fromMap(maps[i]));
  }

  Future<Deck?> getDeckById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Deck.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDeck(Deck deck) async {
    final db = await database;
    return await db.update(
      'decks',
      deck.toMap(),
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  Future<int> deleteDeck(int id) async {
    final db = await database;
    // Primeiro deletar todos os cartões do baralho
    await db.delete('cards', where: 'deck_id = ?', whereArgs: [id]);
    // Depois deletar o baralho
    return await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

  // OPERAÇÕES COM CARTÕES

  Future<int> insertCard(CardModel card) async {
    final db = await database;
    return await db.insert('cards', card.toMap());
  }

  Future<List<CardModel>> getCardsByDeckId(int deckId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'last_viewed ASC, created_at ASC', // Cartões menos visualizados primeiro
    );
    return List.generate(maps.length, (i) => CardModel.fromMap(maps[i]));
  }

  Future<CardModel?> getCardById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CardModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCard(CardModel card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  // Obter próximo cartão para visualização (o que faz mais tempo que não foi visto)
  Future<CardModel?> getNextCardToView(int deckId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'last_viewed ASC, created_at ASC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CardModel.fromMap(maps.first);
    }
    return null;
  }

  // Contar cartões em um baralho
  Future<int> getCardCountByDeckId(int deckId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE deck_id = ?',
      [deckId],
    );
    return result.first['count'] as int;
  }

  // Obter baralho padrão
  Future<Deck> getDefaultDeck() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'title = ?',
      whereArgs: ['Baralho sem título'],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Deck.fromMap(maps.first);
    }
    // Se não existir, criar um novo
    final defaultDeck = Deck.create('Baralho sem título');
    final id = await insertDeck(defaultDeck);
    return defaultDeck.copyWith(id: id);
  }

  // Fechar banco de dados
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

