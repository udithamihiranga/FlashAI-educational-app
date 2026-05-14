import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flashai/features/mastery/presentation/models/mastery_log.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';

class MasteryLogRepository extends ChangeNotifier {
  final Map<String, MasteryProgressLog> _logs = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, MasteryProgressLog> get logs => Map.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
  }

  MasteryProgressLog getOrCreateLog(SavedNote note) {
    if (!_logs.containsKey(note.id)) {
      final topics = note.flashcards
          .map((fc) => TopicMastery(
                topic: fc.question.length > 50 ? '${fc.question.substring(0, 50)}...' : fc.question,
                noteId: note.id,
                level: MasteryLevel.unfamiliar,
              ))
          .toList();
      
      _logs[note.id] = MasteryProgressLog(noteId: note.id, topics: topics);
    }
    return _logs[note.id]!;
  }

  Future<void> recordFlashcardResult(
    String noteId,
    String flashcardQuestion,
    bool correct,
  ) async {
    final log = _logs[noteId];
    if (log == null) return;

    final topicIndex = log.topics.indexWhere(
      (t) => t.topic.toLowerCase().contains(flashcardQuestion.toLowerCase().substring(0, min(20, flashcardQuestion.length))),
    );

    if (topicIndex >= 0) {
      final updatedTopics = List<TopicMastery>.from(log.topics);
      updatedTopics[topicIndex] = correct
          ? updatedTopics[topicIndex].recordCorrect()
          : updatedTopics[topicIndex].recordIncorrect();
      
      _logs[noteId] = MasteryProgressLog(noteId: noteId, topics: updatedTopics);
      notifyListeners();
    }
  }

  List<TopicMastery> getTopicsNeedingReview(String noteId) {
    final log = _logs[noteId];
    return log?.topicsNeedingReview ?? [];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int min(int a, int b) => a < b ? a : b;
}