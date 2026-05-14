import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flashai/features/notes/presentation/services/ai_service.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';

class OpenRouterService {
  static final OpenRouterService _instance = OpenRouterService._internal();
  factory OpenRouterService() => _instance;
  OpenRouterService._internal();

  String? _apiKey;
  String? _baseUrl;
  String? _model;

  Future<void> initialize() async {
    _apiKey = dotenv.env['OPENROUTER_API_KEY'];
    _baseUrl = dotenv.env['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1';

    /// 🔥 BEST BALANCE MODEL (you can upgrade later)
    _model = dotenv.env['OPENROUTER_MODEL'] ?? 'anthropic/claude-3-sonnet';

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OPENROUTER_API_KEY not found');
    }
  }

  /// 🔥 IMPROVED CLEANER
  String cleanInput(String text) {
    return text
        .replaceAll(RegExp(r'\d+\s'), '')
        .replaceAll('•', '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll('---', '')
        .trim();
  }

  Future<String> generateNotes({
    required String title,
    required String content,
  }) async {
    if (_apiKey == null) await initialize();

    final cleanedContent = cleanInput(content);
    final url = '$_baseUrl/chat/completions';

    /// 🔥 STRICTER PROMPT (MAJOR IMPROVEMENT)
    final prompt = '''You are a STRICT ACADEMIC AI SYSTEM.

You MUST:
- Understand messy lecture content
- Clean it internally
- Rewrite it into structured study notes
- Generate high-quality flashcards

----------------------------------------

🚨 STRICT RULES (VERY IMPORTANT):
- DO NOT copy raw text
- DO NOT repeat sentences
- DO NOT add study tips
- DO NOT include explanations outside format
- DO NOT break JSON format
- DO NOT include markdown inside JSON

----------------------------------------

🎯 OUTPUT FORMAT:

# $title

## 📌 Key Concepts
- Clear rewritten concepts only

## 🔹 Components
- Important elements

## ⚡ Working Process
- Step-by-step explanation

## 📊 Types / Classification
- Proper categories

## ⚖️ Advantages
- Clean points

## ❌ Disadvantages
- Clean points

## 🧠 Summary
- Short final summary

----------------------------------------

🧠 FLASHCARDS (VERY IMPORTANT):

- Generate 20–40 flashcards (minimum 20)
- Based ONLY on final cleaned notes
- Must include:
  - definitions
  - processes
  - comparisons
  - important facts

FORMAT (STRICT JSON ONLY):
[
  {
    "question": "string",
    "answer": "string"
  }
]

RULES:
- No markdown inside JSON
- No extra keys
- No explanation text
- No trailing commas

----------------------------------------

FINAL OUTPUT:
1. Markdown Notes
2. JSON Flashcards ONLY

----------------------------------------

CONTENT:
$cleanedContent
''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost:3000',
          'X-Title': 'FlashAI Notes Generator',
        },
        body: jsonEncode({
          'model': _model,

          /// 🔥 LOWER TEMP = MORE ACCURATE
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a strict academic assistant that generates structured notes and valid JSON flashcards only.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],

          'temperature': 0.5,
          'top_p': 0.85,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Generation failed: $e');
    }
  }

  Future<GeneratedStudyMaterial> generateStudyMaterial({
    required String title,
    required String content,
  }) async {
    if (_apiKey == null) await initialize();

    final cleanedContent = cleanInput(content);
    final url = '$_baseUrl/chat/completions';

    final prompt = '''You are an advanced educational AI that generates:
1. High-fidelity structured notes with Summary Boxes
2. Comprehensive Anki-style flashcards

Format the output as:
MARKDOWN_NOTES_START
[Full markdown notes with headings, subheadings, bold terms, bullet lists, and Summary Boxes]
MARKDOWN_NOTES_END

FLASHCARDS_START
[{"question":"...","answer":"..."}]
FLASHCARDS_END

CONTENT:
$cleanedContent
''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost:3000',
          'X-Title': 'FlashAI Study Material Generator',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a strict educational AI. Output only the specified format.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'top_p': 0.9,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'].trim();
        
        return _parseStudyMaterial(responseText, title);
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Generation failed: $e');
    }
  }

  GeneratedStudyMaterial _parseStudyMaterial(String response, String title) {
    final notesStart = response.indexOf('MARKDOWN_NOTES_START');
    final notesEnd = response.indexOf('MARKDOWN_NOTES_END');
    final cardsStart = response.indexOf('FLASHCARDS_START');
    final cardsEnd = response.indexOf('FLASHCARDS_END');

    String notes = '';
    List<Flashcard> flashcards = [];
    List<String> topics = [];

    if (notesStart != -1 && notesEnd != -1) {
      notes = response.substring(notesStart + 'MARKDOWN_NOTES_START'.length, notesEnd).trim();
      topics = _extractTopics(notes);
    }

    if (cardsStart != -1 && cardsEnd != -1) {
      final cardsJson = response.substring(cardsStart + 'FLASHCARDS_START'.length, cardsEnd).trim();
      try {
        final List<dynamic> cardsList = jsonDecode(cardsJson);
        flashcards = cardsList.map((c) => Flashcard(
          question: c['question'] ?? '',
          answer: c['answer'] ?? '',
          category: title,
        )).toList();
      } catch (e) {
        flashcards = [];
      }
    }

    return GeneratedStudyMaterial(
      title: title,
      notes: notes.isEmpty ? '# Study Notes\n\nNo content generated.' : notes,
      flashcards: flashcards,
      topics: topics,
    );
  }

  List<String> _extractTopics(String notes) {
    final topics = <String>[];
    final headingPattern = RegExp(r'^##\s+(.+)$', multiLine: true);
    for (final match in headingPattern.allMatches(notes)) {
      topics.add(match.group(1)?.trim() ?? '');
    }
    return topics;
  }

  /// 🔥 STREAM VERSION (same logic improved)
  Stream<String> generateNotesStream({
    required String title,
    required String content,
  }) async* {
    if (_apiKey == null) await initialize();

    final cleanedContent = cleanInput(content);
    final url = '$_baseUrl/chat/completions';

    final prompt = '''Generate structured notes + 20–40 flashcards.

Title: $title

Content:
$cleanedContent

Return ONLY:
1. Markdown notes
2. JSON flashcards
''';

    try {
      final request = http.Request('POST', Uri.parse(url))
        ..headers.addAll({
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'Strict generator for structured notes and JSON flashcards.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.5,
          'top_p': 0.85,
          'max_tokens': 4000,
          'stream': true,
        });

      final response = await request.send();

      final stream = response.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());

      await for (final line in stream) {
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
      throw Exception('Stream error: $e');
    }
  }
}