import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/notes/presentation/services/note_database_service.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_database.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';
import 'package:flashai/features/notes/presentation/services/ai_service.dart';

class NotesRepository extends ChangeNotifier {
  final NoteDatabase _db = NoteDatabase();
  final FlashcardDatabase _flashcardDb = FlashcardDatabase();
  List<SavedNote> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  FlashcardProgressRepository? _flashcardProgressRepo;

  List<SavedNote> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get notesCount => _notes.length;

  void setFlashcardProgressRepository(FlashcardProgressRepository repo) {
    _flashcardProgressRepo = repo;
    // Listen to flashcard progress changes and sync automatically
    repo.addListener(_onFlashcardProgressChanged);
  }

  void _onFlashcardProgressChanged() {
    if (_flashcardProgressRepo != null) {
      syncFlashcardProgress(_flashcardProgressRepo!.cards);
    }
  }

  // Sync flashcard progress from FlashcardProgressRepository into notes
  Future<void> syncFlashcardProgress(List<Flashcard> trackedCards) async {
    try {
      final cardMap = {for (var card in trackedCards) card.id: card};

      // Update notes' flashcards with latest progress data
      final updatedNotes = _notes.map((note) {
        final updatedFlashcards = note.flashcards.map((card) {
          final tracked = cardMap[card.id];
          if (tracked != null) {
            return tracked;
          }
          return card;
        }).toList();

        if (updatedFlashcards != note.flashcards) {
          return note.copyWith(flashcards: updatedFlashcards, updatedAt: DateTime.now());
        }
        return note;
      }).toList();

      _notes = updatedNotes;
      notifyListeners();
    } catch (e) {
      print('Error syncing flashcard progress: $e');
    }
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await _db.getAllNotes();
      
      // If no notes exist, seed with sample Flutter Overview data
      if (_notes.isEmpty) {
        await _seedSampleData();
      }

      // Sync flashcard progress after notes are loaded
      if (_flashcardProgressRepo != null) {
        syncFlashcardProgress(_flashcardProgressRepo!.cards);
      }
    } catch (e) {
      _errorMessage = 'Failed to load notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Seeds the database with the Flutter Overview sample note and flashcards.
  /// Only called when no notes exist (first run).
  Future<void> _seedSampleData() async {
    try {
      final flutterOverviewNote = SavedNote(
        title: 'Flutter Overview',
        content: '''Flutter Overview

Open-source UI toolkit developed by Google
Used to build cross-platform apps (Android, iOS, Web, Desktop)
Uses a single codebase for multiple platforms

Core Features

Fast development with Hot Reload
Rich set of customizable widgets
High performance using Dart language
Native-like performance without bridge

Architecture

Based on widget tree structure
Everything in Flutter is a widget
Two main types:
Stateless Widgets (static UI)
Stateful Widgets (dynamic UI)

Dart Language

Programming language used in Flutter
Object-oriented and optimized for UI
Supports asynchronous programming

UI Design

Uses Material Design (Android style)
Supports Cupertino (iOS style)
Flexible layout system (Row, Column, Stack)

Advantages

Faster development time
Cross-platform support
Strong community support
Custom UI easily achievable''',
        flashcards: [
          Flashcard(
            question: 'What is Flutter?',
            answer: 'An open-source UI toolkit by Google for building cross-platform apps.',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'Which programming language is used in Flutter?',
            answer: 'Dart',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'What is Hot Reload?',
            answer: 'A feature that allows developers to see code changes instantly without restarting the app.',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'What is a widget in Flutter?',
            answer: 'The basic building block of a Flutter UI.',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'Difference between Stateless and Stateful widgets?',
            answer: 'Stateless = no state change, Stateful = UI can change dynamically.',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'What design systems does Flutter support?',
            answer: 'Material Design and Cupertino.',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'Why is Flutter considered high performance?',
            answer: 'It compiles to native code and doesn\'t rely on a bridge.',
            category: 'Flutter',
          ),
          Flashcard(
            question: 'What layout widgets are commonly used?',
            answer: 'Row, Column, Stack',
            category: 'Flutter',
          ),
        ],
      );

      // Insert note into database
      await _db.insertNote(flutterOverviewNote);

      // Save flashcards to progress repository (updates both DB and in-memory list)
      if (_flashcardProgressRepo != null) {
        for (final flashcard in flutterOverviewNote.flashcards) {
          await _flashcardProgressRepo!.saveCard(flashcard);
        }
      } else {
        // Fallback to direct DB if repo not set yet
        for (final flashcard in flutterOverviewNote.flashcards) {
          await _flashcardDb.saveFlashcardProgress(flashcard);
        }
      }

      // Add to local list
      _notes.add(flutterOverviewNote);
    } catch (e) {
      _errorMessage = 'Failed to seed sample data: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<SavedNote?> saveNote({
    required String title,
    required String content,
    bool generateFlashcards = true,
  }) async {
    try {
      final studyMaterial = await AIService.generateStudyMaterial(
        title: title,
        content: content,
      );

      final note = SavedNote(
        title: title,
        content: studyMaterial.notes,
        flashcards: studyMaterial.flashcards,
      );
      await _db.insertNote(note);

      // Save flashcards to progress repository (updates both DB and in-memory list)
      if (_flashcardProgressRepo != null) {
        for (final flashcard in studyMaterial.flashcards) {
          await _flashcardProgressRepo!.saveCard(flashcard);
        }
      } else {
        // Fallback to direct DB if repo not set yet
        for (final flashcard in studyMaterial.flashcards) {
          await _flashcardDb.saveFlashcardProgress(flashcard);
        }
      }

      await loadNotes();
      return note;
    } catch (e) {
      _errorMessage = 'Failed to save note: $e';
      notifyListeners();
      return null;
    }
  }

  Future<SavedNote?> saveGeneratedNote({
    required String title,
    required String content,
    required List<Flashcard> flashcards,
  }) async {
    try {
      final note = SavedNote(
        title: title,
        content: content,
        flashcards: flashcards,
      );
      await _db.insertNote(note);

      if (_flashcardProgressRepo != null) {
        for (final flashcard in flashcards) {
          await _flashcardProgressRepo!.saveCard(flashcard);
        }
      } else {
        for (final flashcard in flashcards) {
          await _flashcardDb.saveFlashcardProgress(flashcard);
        }
      }

      await loadNotes();
      return note;
    } catch (e) {
      _errorMessage = 'Failed to save note: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateNote(SavedNote note) async {
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _db.updateNote(updatedNote);
      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update note: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addFlashcardToNote(String noteId, Flashcard flashcard) async {
    try {
      final note = await _db.getNoteById(noteId);
      if (note == null) {
        _errorMessage = 'Note not found';
        notifyListeners();
        return false;
      }

      final updatedNote = note.copyWith(
        flashcards: [...note.flashcards, flashcard],
      );
      await _db.updateNote(updatedNote);

      // Add to flashcard progress repository
      if (_flashcardProgressRepo != null) {
        await _flashcardProgressRepo!.saveCard(flashcard);
      } else {
        await _flashcardDb.saveFlashcardProgress(flashcard);
      }

      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add flashcard: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFlashcardFromNote(String noteId, String flashcardId) async {
    try {
      final note = await _db.getNoteById(noteId);
      if (note == null) {
        _errorMessage = 'Note not found';
        notifyListeners();
        return false;
      }

      final updatedNote = note.copyWith(
        flashcards: note.flashcards.where((fc) => fc.id != flashcardId).toList(),
      );
      await _db.updateNote(updatedNote);

      // Remove from flashcard progress repository
      if (_flashcardProgressRepo != null) {
        await _flashcardProgressRepo!.deleteCard(flashcardId);
      } else {
        await _flashcardDb.deleteFlashcard(flashcardId);
      }

      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove flashcard: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      final note = await _db.getNoteById(id);
      if (note == null) {
        _errorMessage = 'Note not found';
        notifyListeners();
        return false;
      }

      // Delete associated flashcards from progress repository
      if (_flashcardProgressRepo != null) {
        for (final flashcard in note.flashcards) {
          await _flashcardProgressRepo!.deleteCard(flashcard.id);
        }
      } else {
        for (final flashcard in note.flashcards) {
          await _flashcardDb.deleteFlashcard(flashcard.id);
        }
      }

      await _db.deleteNote(id);
      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete note: $e';
      notifyListeners();
      return false;
    }
  }

    Future<void> clearAllNotes() async {
      try {
        // Clear all flashcards from progress repository
        if (_flashcardProgressRepo != null) {
          await _flashcardProgressRepo!.clearAllCards();
        } else {
          await _flashcardDb.clearAllFlashcards();
        }
        _notes = [];
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to clear notes: $e';
        notifyListeners();
      }
    }

   Future<SavedNote?> getNoteById(String id) async {
     try {
       return await _db.getNoteById(id);
     } catch (e) {
       return null;
     }
   }

   @override
   void dispose() {
     _flashcardProgressRepo?.removeListener(_onFlashcardProgressChanged);
     super.dispose();
   }

    void clearError() {
      _errorMessage = null;
      notifyListeners();
    }
  }
