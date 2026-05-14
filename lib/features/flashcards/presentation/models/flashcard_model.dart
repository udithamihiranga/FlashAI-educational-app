import 'package:uuid/uuid.dart';

enum FlashcardType {
  basic('Basic'),
  cloze('Cloze Deletion');

  const FlashcardType(this.label);
  final String label;
}

enum FlashcardDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const FlashcardDifficulty(this.label);
  final String label;
}

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String category;
  final FlashcardType type;
  final FlashcardDifficulty difficulty;
  final bool studied;
  final int correctCount;
  final int incorrectCount;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final String? clozeHint;

  Flashcard({
    String? id,
    required this.question,
    required this.answer,
    required this.category,
    this.type = FlashcardType.basic,
    this.difficulty = FlashcardDifficulty.medium,
    this.studied = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.lastReviewed,
    this.nextReview,
    this.clozeHint,
  }) : id = id ?? const Uuid().v4();

  double get accuracy => correctCount + incorrectCount == 0
      ? 0
      : correctCount / (correctCount + incorrectCount);

  bool get needsReview => nextReview != null && nextReview!.isBefore(DateTime.now());

  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    FlashcardType? type,
    FlashcardDifficulty? difficulty,
    bool? studied,
    int? correctCount,
    int? incorrectCount,
    DateTime? lastReviewed,
    DateTime? nextReview,
    String? clozeHint,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      studied: studied ?? this.studied,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      clozeHint: clozeHint ?? this.clozeHint,
    );
  }

  Flashcard recordCorrect() {
    final newCorrect = correctCount + 1;
    final newAccuracy = newCorrect / (newCorrect + incorrectCount);
    
    DateTime? nextReviewDate;
    if (newAccuracy >= 0.9 && newCorrect >= 3) {
      nextReviewDate = DateTime.now().add(const Duration(days: 7));
    } else if (newAccuracy >= 0.7) {
      nextReviewDate = DateTime.now().add(const Duration(days: 2));
    } else {
      nextReviewDate = DateTime.now().add(const Duration(hours: 12));
    }

    return copyWith(
      studied: true,
      correctCount: newCorrect,
      lastReviewed: DateTime.now(),
      nextReview: nextReviewDate,
    );
  }

  Flashcard recordIncorrect() {
    return copyWith(
      studied: true,
      incorrectCount: incorrectCount + 1,
      lastReviewed: DateTime.now(),
      nextReview: DateTime.now().add(const Duration(hours: 4)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'type': type.name,
      'difficulty': difficulty.name,
      'studied': studied,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'lastReviewed': lastReviewed?.millisecondsSinceEpoch,
      'nextReview': nextReview?.millisecondsSinceEpoch,
      'clozeHint': clozeHint,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'General',
      type: FlashcardType.values.byName(map['type'] ?? 'basic'),
      difficulty: FlashcardDifficulty.values.byName(map['difficulty'] ?? 'medium'),
      studied: map['studied'] ?? false,
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      lastReviewed: map['lastReviewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewed'])
          : null,
      nextReview: map['nextReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextReview'])
          : null,
      clozeHint: map['clozeHint'],
    );
  }
}

// Sample data removed - using Flutter Overview note from NotesRepository instead