import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';

class FlashcardDatabase {
  static final FlashcardDatabase _instance = FlashcardDatabase._internal();
  factory FlashcardDatabase() => _instance;
  FlashcardDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'flashcard_progress.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flashcard_progress(
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'basic',
        difficulty TEXT NOT NULL DEFAULT 'medium',
        studied INTEGER NOT NULL DEFAULT 0,
        correctCount INTEGER NOT NULL DEFAULT 0,
        incorrectCount INTEGER NOT NULL DEFAULT 0,
        lastReviewed INTEGER,
        nextReview INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_flashcard_category ON flashcard_progress(category)
    ''');
  }

  Future<void> saveFlashcardProgress(Flashcard card) async {
    final db = await database;
    await db.insert(
      'flashcard_progress',
      {
        'id': card.id,
        'question': card.question,
        'answer': card.answer,
        'category': card.category,
        'type': card.type.name,
        'difficulty': card.difficulty.name,
        'studied': card.studied ? 1 : 0,
        'correctCount': card.correctCount,
        'incorrectCount': card.incorrectCount,
        'lastReviewed': card.lastReviewed?.millisecondsSinceEpoch,
        'nextReview': card.nextReview?.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Flashcard>> loadAllFlashcards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'flashcard_progress',
      orderBy: 'category ASC, id ASC',
    );

    return maps.map((map) => Flashcard(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      category: map['category'],
      type: FlashcardType.values.byName(map['type'] ?? 'basic'),
      difficulty: FlashcardDifficulty.values.byName(map['difficulty'] ?? 'medium'),
      studied: (map['studied'] ?? 0) == 1,
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      lastReviewed: map['lastReviewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewed'])
          : null,
      nextReview: map['nextReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextReview'])
          : null,
    )).toList();
  }

  Future<Flashcard?> getFlashcardById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'flashcard_progress',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Flashcard(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      category: map['category'],
      type: FlashcardType.values.byName(map['type'] ?? 'basic'),
      difficulty: FlashcardDifficulty.values.byName(map['difficulty'] ?? 'medium'),
      studied: (map['studied'] ?? 0) == 1,
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      lastReviewed: map['lastReviewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewed'])
          : null,
      nextReview: map['nextReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextReview'])
          : null,
    );
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final db = await database;
    await db.update(
      'flashcard_progress',
      {
        'studied': card.studied ? 1 : 0,
        'correctCount': card.correctCount,
        'incorrectCount': card.incorrectCount,
        'lastReviewed': card.lastReviewed?.millisecondsSinceEpoch,
        'nextReview': card.nextReview?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteFlashcard(String id) async {
    final db = await database;
    await db.delete(
      'flashcard_progress',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllFlashcards() async {
    final db = await database;
    await db.delete('flashcard_progress');
  }

  Future<Map<String, int>> getProgressStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) as count FROM flashcard_progress'),
    ) ?? 0;

    final reviewed = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) as count FROM flashcard_progress WHERE studied = 1',
      ),
    ) ?? 0;

    final mastered = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*) as count FROM flashcard_progress 
        WHERE correctCount >= 3 AND (correctCount * 1.0 / (correctCount + incorrectCount)) >= 0.9
      '''),
    ) ?? 0;

    return {
      'total': total,
      'reviewed': reviewed,
      'mastered': mastered,
      'unreviewed': total - reviewed,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}