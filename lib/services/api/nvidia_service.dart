import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flashai/features/notes/presentation/services/ai_service.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';

class NvidiaService {
  static final NvidiaService _instance = NvidiaService._internal();
  factory NvidiaService() => _instance;
  NvidiaService._internal();

  String? _apiKey;
  String? _baseUrl;
  String? _model;

  Future<void> initialize() async {
    _apiKey = dotenv.env['NVIDIA_API_KEY'];
    _baseUrl = dotenv.env['NVIDIA_BASE_URL'] ?? 'https://integrate.api.nvidia.com/v1';
    _model = dotenv.env['NVIDIA_MODEL'] ?? 'nvidia/llama-3.1-nemotron-ultra-253b-v1';

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('NVIDIA_API_KEY not found');
    }
  }

  /// Generate structured study notes and flashcards using NVIDIA API
  Future<GeneratedStudyMaterial> generateStudyMaterial({
    required String title,
    required String content,
  }) async {
    if (_apiKey == null) await initialize();

    final cleanedContent = _cleanInput(content);
    final url = '$_baseUrl/chat/completions';

    final prompt = '''You are an educational AI that creates study materials in a SPECIFIC format.

## OUTPUT FORMAT (FOLLOW EXACTLY)

Topic: [TITLE]

[2-3 sentence introduction explaining the topic]

[Bullet points with layer/concept names and descriptions]
• [Name] – [Description]
• [Name] – [Description]
...

👉 [1-2 sentences about importance or key takeaway]

🧠 Flashcards (for Training)
Flashcard 1

Q: [Question 1]
A: [Answer 1]

Flashcard 2

Q: [Question 2]
A: [Answer 2]

... continue numbering sequentially

## RULES
1. Start with "Topic: " followed by the title
2. Write a brief 2-3 sentence introduction
3. Use bullet points (•) for the main content
4. Each bullet: "–" (em dash) separates name from description
5. Use "👉" for the concluding remark
6. Use "🧠 Flashcards (for Training)" header
7. Number flashcards: "Flashcard 1", "Flashcard 2", etc.
8. Format each flashcard as:
   Q: [question]
   A: [answer]
9. Generate 8-15 flashcards
10. No markdown formatting, no bold, no extra spacing
11. Keep everything plain text

Now generate study materials for:

Topic: $title

Content:
$cleanedContent''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a precise educational assistant. Follow the exact output format provided. No markdown, no extra formatting.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.6,
          'top_p': 0.9,
          'max_tokens': 4000,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'].trim();
        return _parseStudyMaterial(responseText, title);
      } else {
        throw Exception('NVIDIA API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('NVIDIA generation failed: $e');
    }
  }

  GeneratedStudyMaterial _parseStudyMaterial(String response, String title) {
    final lines = response.split('\n');
    String notes = '';
    List<Flashcard> flashcards = [];
    List<String> topics = [];

    bool inFlashcards = false;
    String? currentQuestion;
    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // Detect flashcard section start
      if (line.contains('Flashcards') && (line.contains('Training') || line.contains('for Training'))) {
        inFlashcards = true;
        buffer.writeln();
        continue;
      }

      // Detect flashcard number header
      if (RegExp(r'^Flashcard\s+\d+$').hasMatch(line)) {
        inFlashcards = true;
        continue;
      }

      // Detect Q: line (sets inFlashcards if not already)
      if (line.startsWith('Q:') && !inFlashcards) {
        inFlashcards = true;
        currentQuestion = line.substring(2).trim();
        continue;
      }

      // Parse Q: and A:
      if (line.startsWith('Q:') && inFlashcards) {
        currentQuestion = line.substring(2).trim();
        continue;
      }
      if (line.startsWith('A:') && currentQuestion != null && inFlashcards) {
        String answer = line.substring(2).trim();
        final question = currentQuestion;
        currentQuestion = null;
        if (question.isNotEmpty && answer.isNotEmpty) {
          flashcards.add(Flashcard(
            question: question,
            answer: answer,
            category: title,
            type: FlashcardType.basic,
            difficulty: FlashcardDifficulty.medium,
          ));
        }
        continue;
      }

      // Collect notes content (before flashcards)
      if (!inFlashcards) {
        buffer.writeln(line);
      }
    }

    notes = buffer.toString().trim();

    // Extract topics from bullet points
    final bulletPattern = RegExp(r'^•\s+(.+?)(?:\s+–|—|-|$)');
    for (final match in bulletPattern.allMatches(notes)) {
      final topic = match.group(1)?.trim() ?? '';
      if (topic.isNotEmpty && topic.length < 50) {
        topics.add(topic);
      }
      if (topics.length >= 8) break;
    }

    // Fallback: extract from concept lines with em dash
    if (topics.isEmpty) {
      final conceptPattern = RegExp(r'^(.+?)\s+–\s+(.+)$');
      for (final match in conceptPattern.allMatches(notes)) {
        final concept = match.group(1)?.trim() ?? '';
        if (concept.isNotEmpty && concept.length < 50) {
          topics.add(concept);
        }
        if (topics.length >= 8) break;
      }
    }

    if (notes.isEmpty) {
      notes = '# $title\n\nNo notes generated.';
    }

    return GeneratedStudyMaterial(
      title: title,
      notes: notes,
      flashcards: flashcards,
      topics: topics,
    );
  }

  String _cleanInput(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    const maxLength = 10000;
    if (cleaned.length > maxLength) {
      cleaned = '${cleaned.substring(0, maxLength)}...';
    }
    return cleaned;
  }

  /// Stream version for real-time note generation
  Stream<String> generateNotesStream({
    required String title,
    required String content,
  }) async* {
    if (_apiKey == null) await initialize();

    final cleanedContent = _cleanInput(content);
    final url = '$_baseUrl/chat/completions';

    final prompt = '''Create study materials in this exact format:

Topic: $title

[2-3 sentence introduction]

• [Concept] – [Description]
• [Concept] – [Description]

👉 [Key takeaway]

🧠 Flashcards (for Training)
Flashcard 1
Q: [Question]
A: [Answer]

Flashcard 2
Q: [Question]
A: [Answer]

Content to study:
$cleanedContent''';

    try {
      final request = http.Request('POST', Uri.parse(url))
        ..headers.addAll({
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.6,
          'top_p': 0.9,
          'max_tokens': 4000,
          'stream': true,
        });

      final response = await request.send();

      await for (final line in response.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];
            if (delta.containsKey('content')) {
              yield delta['content'];
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      throw Exception('NVIDIA stream error: $e');
    }
  }
}
