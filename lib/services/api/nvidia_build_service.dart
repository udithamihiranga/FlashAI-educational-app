import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flashai/features/notes/presentation/services/ai_service.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';

class NvidiaBuildService {
  static final NvidiaBuildService _instance = NvidiaBuildService._internal();
  factory NvidiaBuildService() => _instance;
  NvidiaBuildService._internal();

  String? _apiKey;
  String? _baseUrl;
  String? _model;
  String _authHeaderName = 'Authorization';

  Future<void> initialize() async {
    _apiKey = dotenv.env['NVIDIA_BUILD_API_KEY'];
    _baseUrl = dotenv.env['NVIDIA_BUILD_BASE_URL'] ?? 'https://integrate.api.nvidia.com/v1';
    _model = dotenv.env['NVIDIA_BUILD_MODEL'];
    _authHeaderName = dotenv.env['NVIDIA_BUILD_AUTH_HEADER'] ?? 'Authorization';

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('NVIDIA_BUILD_API_KEY not found');
    }

    if (_model == null || _model!.isEmpty) {
      throw Exception('NVIDIA_BUILD_MODEL not found');
    }
  }

  Map<String, String> _buildAuthHeaders() {
    final headers = <String, String>{
      'Authorization': 'Bearer $_apiKey',
    };

    final customHeader = _authHeaderName.trim();
    if (customHeader.isNotEmpty && customHeader.toLowerCase() != 'authorization') {
      headers[customHeader] = _apiKey ?? '';
    }

    return headers;
  }

  void _debugLogRequest(String url, Map<String, String> headers) {
    if (kDebugMode) {
      debugPrint(
        'NVIDIA Build request: url=$url, model=$_model, authHeaderName=$_authHeaderName, '
        'hasAuthorization=${headers.containsKey('Authorization')}',
      );
    }
  }

  String cleanInput(String text) {
    final lines = text.split('\n');
    final sourceLabelPattern = RegExp(r'^---\s*(Manual Text Input|From PDF:.*)\s*---$');
    final cleanedLines = lines
        .where((line) => !sourceLabelPattern.hasMatch(line.trim()))
        .map((line) {
          final stripped = line.replaceFirst(RegExp(r'^\s*\d+\s+'), '');
          return stripped.replaceAll('•', '-');
        })
        .toList();

    return cleanedLines
        .join('\n')
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

    final prompt = '''You are a strict academic assistant.

Use ONLY the information in the CONTENT section. Do NOT add external facts.
If the content is insufficient, say "Insufficient content to generate notes." and return an empty flashcard list.

OUTPUT FORMAT:
1) Markdown notes (clean, structured, concise)
2) JSON flashcards

NOTES REQUIREMENTS:
- Use the title: $title
- Use only content-derived concepts
- No filler or generic study tips

FLASHCARDS REQUIREMENTS:
- 20-40 flashcards if content is sufficient
- Use only content-derived facts
- JSON array only: [{"question":"...","answer":"..."}]

CONTENT:
$cleanedContent
''';

    try {
      final headers = {
        ..._buildAuthHeaders(),
        'Content-Type': 'application/json',
      };
      _debugLogRequest(url, headers);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'model': _model,
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

    final prompt = '''You are an academic assistant.

Use ONLY the information in the CONTENT section. Do NOT add external facts.
If the content is insufficient, output:
MARKDOWN_NOTES_START
Insufficient content to generate notes.
MARKDOWN_NOTES_END
FLASHCARDS_START
[]
FLASHCARDS_END

Format the output as:
MARKDOWN_NOTES_START
[Detailed markdown notes with headings, subheadings, bold terms, bullet lists, examples derived from the content, and a short summary box per section]
MARKDOWN_NOTES_END

FLASHCARDS_START
[{"question":"...","answer":"..."}]
FLASHCARDS_END

NOTES REQUIREMENTS:
- Derive headings from the content (not a generic template)
- Include definitions, key processes, cause/effect, comparisons, and common misconceptions if present in the content
- Use short paragraphs and bullet lists for readability
- Add a final "Key Takeaways" section with 5-8 bullets

FLASHCARDS REQUIREMENTS:
- 20-40 flashcards when content is sufficient
- Use only content-derived facts
- Mix: definitions, steps, comparisons, and factual recall

CONTENT:
$cleanedContent
''';

    try {
      final headers = {
        ..._buildAuthHeaders(),
        'Content-Type': 'application/json',
      };
      _debugLogRequest(url, headers);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
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
      notes = response
          .substring(notesStart + 'MARKDOWN_NOTES_START'.length, notesEnd)
          .trim();
      topics = _extractTopics(notes);
    }

    if (cardsStart != -1 && cardsEnd != -1) {
      final cardsJson = response
          .substring(cardsStart + 'FLASHCARDS_START'.length, cardsEnd)
          .trim();
      flashcards = _tryParseFlashcards(cardsJson, title);
    }

    if (notes.isEmpty) {
      final fallbackNotes = _stripJsonFlashcards(response).trim();
      if (fallbackNotes.isNotEmpty) {
        notes = fallbackNotes;
        topics = _extractTopics(notes);
      }
    }

    if (flashcards.isEmpty) {
      flashcards = _tryParseFlashcards(response, title);
    }

    final safeNotes = notes.isNotEmpty
        ? notes
        : '# Study Notes\n\nNo content generated.';

    return GeneratedStudyMaterial(
      title: title,
      notes: safeNotes,
      flashcards: flashcards,
      topics: topics,
    );
  }

  List<Flashcard> _tryParseFlashcards(String response, String title) {
    final jsonArrayPattern = RegExp(r'\[\s*\{[\s\S]*?\}\s*\]', multiLine: true);
    final match = jsonArrayPattern.firstMatch(response);
    if (match == null) {
      return [];
    }

    final cardsJson = response.substring(match.start, match.end).trim();
    try {
      final List<dynamic> cardsList = jsonDecode(cardsJson);
      return cardsList
          .map((c) => Flashcard(
                question: c['question'] ?? '',
                answer: c['answer'] ?? '',
                category: title,
              ))
          .where((c) => c.question.isNotEmpty && c.answer.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _stripJsonFlashcards(String response) {
    final jsonArrayPattern = RegExp(r'\[\s*\{[\s\S]*?\}\s*\]', multiLine: true);
    return response.replaceFirst(jsonArrayPattern, '').trim();
  }

  List<String> _extractTopics(String notes) {
    final topics = <String>[];
    final headingPattern = RegExp(r'^##\s+(.+)$', multiLine: true);
    for (final match in headingPattern.allMatches(notes)) {
      topics.add(match.group(1)?.trim() ?? '');
    }
    return topics;
  }

  Stream<String> generateNotesStream({
    required String title,
    required String content,
  }) async* {
    if (_apiKey == null) await initialize();

    final cleanedContent = cleanInput(content);
    final url = '$_baseUrl/chat/completions';

    final prompt = '''Generate structured notes and flashcards using ONLY the content.

Title: $title

Content:
$cleanedContent

Return ONLY:
1. Markdown notes
2. JSON flashcards
''';

    try {
      final headers = {
        ..._buildAuthHeaders(),
        'Content-Type': 'application/json',
      };
      _debugLogRequest(url, headers);
      final request = http.Request('POST', Uri.parse(url))
        ..headers.addAll(headers)
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
      throw Exception('Stream error: $e');
    }
  }
}
