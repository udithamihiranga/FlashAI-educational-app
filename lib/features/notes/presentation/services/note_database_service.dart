import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';

class NoteDatabase {
  static final NoteDatabase _instance = NoteDatabase._internal();
  factory NoteDatabase() => _instance;
  NoteDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'notes_database.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE note_flashcards(
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT NOT NULL,
        FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE note_flashcards(
            id TEXT PRIMARY KEY,
            noteId TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            category TEXT NOT NULL,
            FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
          )
        ''');
      }
    } catch (e) {
      throw Exception('Failed to upgrade database from v$oldVersion to v$newVersion: $e');
    }
  }

  Future<int> insertNote(SavedNote note) async {
    if (note.title.isEmpty || note.content.isEmpty) {
      throw ArgumentError('Note must have a title and content');
    }

    final db = await database;
    return await db.transaction((txn) async {
      try {
        final noteResult = await txn.insert(
          'notes',
          {
            'id': note.id,
            'title': note.title,
            'content': note.content,
            'createdAt': note.createdAt.millisecondsSinceEpoch,
            'updatedAt': note.updatedAt.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Only insert flashcards if they exist
        if (note.flashcards.isNotEmpty) {
          for (final fc in note.flashcards) {
            if (fc.question.isEmpty || fc.answer.isEmpty) {
              continue; // Skip invalid flashcards
            }
            await txn.insert(
              'note_flashcards',
              {
                'id': fc.id,
                'noteId': note.id,
                'question': fc.question,
                'answer': fc.answer,
                'category': fc.category,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return noteResult;
      } catch (e) {
        throw Exception('Failed to insert note: $e');
      }
    });
  }

  Future<List<SavedNote>> getAllNotes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        orderBy: 'updatedAt DESC',
      );

      final notes = <SavedNote>[];
      for (final map in maps) {
        try {
          final flashcards = await _getFlashcardsForNote(db, map['id'] as String);
          final noteMap = Map<String, dynamic>.from(map);
          noteMap['flashcards'] = flashcards;
          notes.add(SavedNote.fromMap(noteMap));
        } catch (e) {
          // Log corrupted note but continue processing other notes
          print('Warning: Skipping corrupted note with id: ${map['id']}, error: $e');
          continue;
        }
      }
      return notes;
    } catch (e) {
      // Return empty list on database errors to prevent app crash
      print('Error loading notes from database: $e');
      return [];
    }
  }

  Future<SavedNote?> getNoteById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final flashcards = await _getFlashcardsForNote(db, id);
    final noteMap = Map<String, dynamic>.from(maps.first);
    noteMap['flashcards'] = flashcards;
    return SavedNote.fromMap(noteMap);
  }

  Future<List<Map<String, dynamic>>> _getFlashcardsForNote(Database db, String noteId) async {
    return await db.query(
      'note_flashcards',
      where: 'noteId = ?',
      whereArgs: [noteId],
    );
  }

  Future<int> updateNote(SavedNote note) async {
    if (note.id.isEmpty) {
      throw ArgumentError('Note ID cannot be empty');
    }
    if (note.title.isEmpty || note.content.isEmpty) {
      throw ArgumentError('Note must have a title and content');
    }

    final db = await database;
    return await db.transaction((txn) async {
      try {
        final result = await txn.update(
          'notes',
          {
            'title': note.title,
            'content': note.content,
            'updatedAt': note.updatedAt.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [note.id],
        );

        if (result == 0) {
          throw Exception('Note not found for update: ${note.id}');
        }

        // Delete existing flashcards and insert new ones
        await txn.delete(
          'note_flashcards',
          where: 'noteId = ?',
          whereArgs: [note.id],
        );

        // Insert new flashcards if any
        if (note.flashcards.isNotEmpty) {
          for (final fc in note.flashcards) {
            if (fc.question.isEmpty || fc.answer.isEmpty) {
              continue; // Skip invalid flashcards
            }
            await txn.insert(
              'note_flashcards',
              {
                'id': fc.id,
                'noteId': note.id,
                'question': fc.question,
                'answer': fc.answer,
                'category': fc.category,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return result;
      } catch (e) {
        throw Exception('Failed to update note: $e');
      }
    });
  }

  Future<int> deleteNote(String id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete(
        'note_flashcards',
        where: 'noteId = ?',
        whereArgs: [id],
      );
      return await txn.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<int> deleteAllNotes() async {
    final db = await database;
    await db.delete('note_flashcards');
    return await db.delete('notes');
  }

  Future<int> getNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
