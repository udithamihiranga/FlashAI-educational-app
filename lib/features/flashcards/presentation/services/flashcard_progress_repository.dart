import 'package:flutter/foundation.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_database.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:flashai/features/notes/presentation/services/note_database_service.dart';

class FlashcardProgressRepository extends ChangeNotifier {
  final FlashcardDatabase _db = FlashcardDatabase();
  List<Flashcard> _cards = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Flashcard> get cards => List.unmodifiable(_cards);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCards => _cards.length;
  int get reviewedCount => _cards.where((c) => c.studied || c.correctCount > 0 || c.incorrectCount > 0).length;
  int get masteredCount => _cards.where((c) => c.accuracy >= 0.9 && c.correctCount >= 3).length;
  int get unreviewedCount => totalCards - reviewedCount;

  double get progressPercentage => totalCards > 0 ? reviewedCount / totalCards : 0;

  Future<void> loadCards() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cards = await _db.loadAllFlashcards();
    } catch (e) {
      _errorMessage = 'Failed to load flashcards: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCard(Flashcard card) async {
    try {
      await _db.saveFlashcardProgress(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index >= 0) {
        _cards[index] = card;
      } else {
        _cards.add(card);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save card: $e';
      notifyListeners();
    }
  }

  Future<void> updateCard(Flashcard card) async {
    try {
      await _db.updateFlashcard(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index >= 0) {
        _cards[index] = card;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update card: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCard(String id) async {
    try {
      await _db.deleteFlashcard(id);
      _cards.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete card: $e';
      notifyListeners();
    }
  }

  Future<void> clearAllCards() async {
    try {
      await _db.clearAllFlashcards();
      _cards = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear cards: $e';
      notifyListeners();
    }
  }

  Future<void> recordCorrect(String cardId) async {
    // Ensure cards are loaded if repository is empty
    if (_cards.isEmpty) {
      await loadCards();
    }
    
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index >= 0) {
      final card = _cards[index];
      final updatedCard = card.recordCorrect();
      await updateCard(updatedCard);
    } else {
      // Card not found - might have been deleted, log but don't throw
      debugPrint('Warning: Card $cardId not found in repository during recordCorrect');
    }
  }

  Future<void> recordIncorrect(String cardId) async {
    // Ensure cards are loaded if repository is empty
    if (_cards.isEmpty) {
      await loadCards();
    }
    
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index >= 0) {
      final card = _cards[index];
      final updatedCard = card.recordIncorrect();
      await updateCard(updatedCard);
    } else {
      debugPrint('Warning: Card $cardId not found in repository during recordIncorrect');
    }
  }

  Future<void> markAsDone(String cardId) async {
    // Ensure cards are loaded if repository is empty
    if (_cards.isEmpty) {
      await loadCards();
    }
    
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index >= 0) {
      final card = _cards[index];
      final now = DateTime.now();
      final updatedCard = card.copyWith(
        studied: true,
        correctCount: card.correctCount + 1,
        lastReviewed: now,
        nextReview: now.add(const Duration(days: 1)),
      );
      await updateCard(updatedCard);
    } else {
      debugPrint('Warning: Card $cardId not found in repository during markAsDone');
    }
  }

  Future<Map<String, int>> getSubjectProgress() async {
    final Map<String, int> subjectProgress = {};

    for (final card in _cards) {
      subjectProgress[card.category] = (subjectProgress[card.category] ?? 0) +
          (card.studied || card.correctCount > 0 || card.incorrectCount > 0 ? 1 : 0);
    }

    return subjectProgress;
  }

  Future<void> syncProgressToNotes(NotesRepository notesRepo) async {
    try {
      final notes = notesRepo.notes;
      final cardMap = {for (var card in _cards) card.id: card};

      for (final note in notes) {
        final updatedFlashcards = note.flashcards.map((card) {
          final tracked = cardMap[card.id];
          return tracked ?? card;
        }).toList();

        if (updatedFlashcards != note.flashcards) {
          final noteDb = NoteDatabase();
          final updatedNote = note.copyWith(
            flashcards: updatedFlashcards,
            updatedAt: DateTime.now(),
          );
          await noteDb.updateNote(updatedNote);
        }
      }

      await notesRepo.loadNotes();
    } catch (e) {
      debugPrint('Error syncing progress to notes: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}