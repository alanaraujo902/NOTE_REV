import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';

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
    String path = join(documentsDirectory.path, 'card_deck.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        imagePath TEXT,
        drawingPath TEXT,
        createdAt INTEGER NOT NULL,
        lastReviewed INTEGER NOT NULL,
        reviewCount INTEGER DEFAULT 0,
        position INTEGER NOT NULL
      )
    ''');
  }

  // Insert a new card
  Future<int> insertCard(CardModel card) async {
    final db = await database;
    int position = card.position;
    if (position == -1) {
      final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT MAX(position) as maxPosition FROM cards'
      );
      position = (result.first['maxPosition'] ?? -1) + 1;
    }
    final cardWithPosition = card.copyWith(position: position);
    return await db.insert('cards', cardWithPosition.toMap());
  }

  // Get all cards ordered by position
  Future<List<CardModel>> getAllCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      orderBy: 'position ASC',
    );

    return List.generate(maps.length, (i) {
      return CardModel.fromMap(maps[i]);
    });
  }

  // Get card by ID
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

  // Update a card
  Future<int> updateCard(CardModel card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // Delete a card
  Future<int> deleteCard(int id) async {
    final db = await database;
    
    // Get the card to be deleted to know its position
    final cardToDelete = await getCardById(id);
    if (cardToDelete == null) return 0;
    
    // Delete the card
    final result = await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Update positions of cards that come after the deleted card
    await db.rawUpdate(
      'UPDATE cards SET position = position - 1 WHERE position > ?',
      [cardToDelete.position],
    );
    
    return result;
  }

  // Mark card as reviewed (move to end of queue)
  Future<void> markCardAsReviewed(int cardId) async {
    final db = await database;
    
    // Get the card
    final card = await getCardById(cardId);
    if (card == null) return;
    
    // Get the maximum position
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(position) as maxPosition FROM cards'
    );
    int maxPosition = result.first['maxPosition'] ?? 0;
    
    // Update all cards that come after this card (decrease their position by 1)
    await db.rawUpdate(
      'UPDATE cards SET position = position - 1 WHERE position > ?',
      [card.position],
    );
    
    // Update the reviewed card
    final updatedCard = card.copyWith(
      position: maxPosition,
      lastReviewed: DateTime.now(),
      reviewCount: card.reviewCount + 1,
    );
    
    await updateCard(updatedCard);
  }

  // Get the next card to review (first in queue)
  Future<CardModel?> getNextCard() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      orderBy: 'position ASC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CardModel.fromMap(maps.first);
    }
    return null;
  }

  // Get total number of cards
  Future<int> getCardCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards'
    );
    return result.first['count'] ?? 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

