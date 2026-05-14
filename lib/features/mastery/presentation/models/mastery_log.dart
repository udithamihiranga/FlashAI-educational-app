import 'package:uuid/uuid.dart';

enum MasteryLevel {
  unfamiliar('New/Unfamiliar'),
  developing('Developing'),
  mastered('Mastered');

  const MasteryLevel(this.label);
  final String label;
}

class TopicMastery {
  final String id;
  final String topic;
  final String noteId;
  final MasteryLevel level;
  final int correctCount;
  final int incorrectCount;
  final DateTime firstStudied;
  final DateTime lastReviewed;
  final DateTime? nextReview;

  TopicMastery({
    String? id,
    required this.topic,
    required this.noteId,
    this.level = MasteryLevel.unfamiliar,
    this.correctCount = 0,
    this.incorrectCount = 0,
    DateTime? firstStudied,
    DateTime? lastReviewed,
    this.nextReview,
  })  : id = id ?? const Uuid().v4(),
        firstStudied = firstStudied ?? DateTime.now(),
        lastReviewed = lastReviewed ?? DateTime.now();

  double get accuracy => correctCount + incorrectCount == 0
      ? 0
      : correctCount / (correctCount + incorrectCount);

  TopicMastery copyWith({
    String? id,
    String? topic,
    String? noteId,
    MasteryLevel? level,
    int? correctCount,
    int? incorrectCount,
    DateTime? firstStudied,
    DateTime? lastReviewed,
    DateTime? nextReview,
  }) {
    return TopicMastery(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      noteId: noteId ?? this.noteId,
      level: level ?? this.level,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      firstStudied: firstStudied ?? this.firstStudied,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'noteId': noteId,
      'level': level.name,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'firstStudied': firstStudied.millisecondsSinceEpoch,
      'lastReviewed': lastReviewed.millisecondsSinceEpoch,
      'nextReview': nextReview?.millisecondsSinceEpoch,
    };
  }

  factory TopicMastery.fromMap(Map<String, dynamic> map) {
    return TopicMastery(
      id: map['id'],
      topic: map['topic'],
      noteId: map['noteId'],
      level: MasteryLevel.values.byName(map['level'] ?? 'unfamiliar'),
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      firstStudied: DateTime.fromMillisecondsSinceEpoch(map['firstStudied']),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(map['lastReviewed']),
      nextReview: map['nextReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextReview'])
          : null,
    );
  }

  TopicMastery recordCorrect() {
    final newCorrect = correctCount + 1;
    final newAccuracy = newCorrect / (newCorrect + incorrectCount);
    MasteryLevel newLevel;

    if (newAccuracy >= 0.9 && newCorrect >= 5) {
      newLevel = MasteryLevel.mastered;
    } else if (newAccuracy >= 0.7) {
      newLevel = MasteryLevel.developing;
    } else {
      newLevel = level;
    }

    return copyWith(
      correctCount: newCorrect,
      lastReviewed: DateTime.now(),
      level: newLevel,
      nextReview: newLevel == MasteryLevel.mastered
          ? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 1)),
    );
  }

  TopicMastery recordIncorrect() {
    return copyWith(
      incorrectCount: incorrectCount + 1,
      lastReviewed: DateTime.now(),
      level: MasteryLevel.unfamiliar,
      nextReview: DateTime.now().add(const Duration(hours: 4)),
    );
  }
}

class MasteryProgressLog {
  final String noteId;
  final List<TopicMastery> topics;

  MasteryProgressLog({
    required this.noteId,
    List<TopicMastery>? topics,
  }) : topics = topics ?? [];

  int get unfamiliarCount =>
      topics.where((t) => t.level == MasteryLevel.unfamiliar).length;

  int get developingCount =>
      topics.where((t) => t.level == MasteryLevel.developing).length;

  int get masteredCount =>
      topics.where((t) => t.level == MasteryLevel.mastered).length;

  double get overallProgress => topics.isEmpty
      ? 0
      : masteredCount / topics.length;

  List<TopicMastery> get topicsNeedingReview => topics
      .where((t) =>
          t.nextReview != null && t.nextReview!.isBefore(DateTime.now()))
      .toList();

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'topics': topics.map((t) => t.toMap()).toList(),
    };
  }

  factory MasteryProgressLog.fromMap(Map<String, dynamic> map) {
    final topicsData = map['topics'] as List<dynamic>? ?? [];
    final topics = topicsData.map((t) => TopicMastery.fromMap(t)).toList();
    return MasteryProgressLog(noteId: map['noteId'], topics: topics);
  }
}