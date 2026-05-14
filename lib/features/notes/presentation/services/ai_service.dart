import 'dart:math';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/services/api/nvidia_build_service.dart';

/// AIService handles AI-powered note generation using NVIDIA Build API.
/// Generates high-fidelity structured notes with Summary Boxes and comprehensive flashcards.
class AIService {
  static final NvidiaBuildService _api = NvidiaBuildService();

  /// Generate comprehensive notes and flashcards from provided content
  static Future<GeneratedStudyMaterial> generateStudyMaterial({
    required String title,
    required String content,
  }) async {
    await _api.initialize();
    return _api.generateStudyMaterial(title: title, content: content);
  }
}

class StudySection {
  final String heading;
  final String content;
  final List<String> keyPoints;

  StudySection({
    required this.heading,
    required this.content,
    required this.keyPoints,
  });

  String get summary => keyPoints.isNotEmpty ? keyPoints.first : content.substring(0, min(100, content.length));
}

class GeneratedStudyMaterial {
  final String title;
  final String notes;
  final List<Flashcard> flashcards;
  final List<String> topics;

  GeneratedStudyMaterial({
    required this.title,
    required this.notes,
    required this.flashcards,
    required this.topics,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'flashcards': flashcards.map((f) => f.toMap()).toList(),
      'topics': topics,
    };
  }

  factory GeneratedStudyMaterial.fromMap(Map<String, dynamic> map) {
    final flashcardsData = map['flashcards'] as List<dynamic>? ?? [];
    final flashcards = flashcardsData.map((f) => Flashcard.fromMap(f)).toList();
    
    return GeneratedStudyMaterial(
      title: map['title'],
      notes: map['notes'],
      flashcards: flashcards,
      topics: List<String>.from(map['topics'] ?? []),
    );
  }
}
