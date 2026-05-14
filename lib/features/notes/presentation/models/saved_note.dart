import 'package:uuid/uuid.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/mastery/presentation/models/mastery_log.dart';

class SavedNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Flashcard> flashcards;
  final MasteryProgressLog? masteryLog;

  SavedNote({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Flashcard>? flashcards,
    this.masteryLog,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        flashcards = flashcards ?? [];

  SavedNote copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Flashcard>? flashcards,
    MasteryProgressLog? masteryLog,
  }) {
    return SavedNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flashcards: flashcards ?? this.flashcards,
      masteryLog: masteryLog ?? this.masteryLog,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'flashcards': flashcards.map((fc) => fc.toMap()).toList(),
      'masteryLog': masteryLog?.toMap(),
    };
  }

  factory SavedNote.fromMap(Map<String, dynamic> map) {
    final flashcardsData = map['flashcards'] as List<dynamic>? ?? [];
    final flashcards = flashcardsData.map((fc) => Flashcard.fromMap(fc)).toList();

    final masteryLogMap = map['masteryLog'] as Map<String, dynamic>?;
    final masteryLog = masteryLogMap != null 
        ? MasteryProgressLog.fromMap(masteryLogMap) 
        : null;

    return SavedNote(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      flashcards: flashcards,
      masteryLog: masteryLog,
    );
  }

  String get preview {
    final maxLength = 100;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get flashcardCountLabel {
    if (flashcards.isEmpty) return 'No flashcards';
    if (flashcards.length == 1) return '1 flashcard';
    return '${flashcards.length} flashcards';
  }
}