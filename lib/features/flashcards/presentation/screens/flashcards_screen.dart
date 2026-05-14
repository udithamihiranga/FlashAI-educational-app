import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/flashcards/presentation/widgets/flashcard_widget.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProgressRepository>().loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.watch<FlashcardProgressRepository>();
    final cards = repository.cards;

    if (repository.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (cards.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Study Flashcards', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        drawer: const AppDrawer(currentIndex: 2),
        body: Center(
          child: Text(
            'No flashcards available.\nCreate notes to generate flashcards.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Card ${_currentIndex + 1}/${cards.length}', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      drawer: const AppDrawer(currentIndex: 2),
      body: SafeArea(
        child: _buildFullScreenCardArea(theme, cards[_currentIndex], repository),
      ),
    );
  }

  Widget _buildFullScreenCardArea(ThemeData theme, Flashcard card, FlashcardProgressRepository repository) {
    return GestureDetector(
      onTap: _toggleAnswer,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -200 && _currentIndex < repository.cards.length - 1) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex++;
            _showAnswer = false;
          });
        } else if (details.primaryVelocity! > 200 && _currentIndex > 0) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex--;
            _showAnswer = false;
          });
        }
      },
      onDoubleTap: () => _markAsKnown(repository),
      onLongPressStart: (_) => _markAsStudy(repository),
      child: Container(
        margin: const EdgeInsets.all(12),
        child: FlashcardWidget(
          card: card,
          showAnswer: _showAnswer,
          onTap: null,
        ),
      ),
    );
  }

  void _toggleAnswer() {
    HapticFeedback.lightImpact();
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _markAsKnown(FlashcardProgressRepository repository) async {
    HapticFeedback.mediumImpact();
    final cardId = repository.cards[_currentIndex].id;
    await repository.recordCorrect(cardId);
    if (!mounted) return;
    _goToNextCard(repository);
  }

  void _markAsStudy(FlashcardProgressRepository repository) async {
    HapticFeedback.lightImpact();
    final cardId = repository.cards[_currentIndex].id;
    await repository.recordIncorrect(cardId);
    if (!mounted) return;
    _showStudyDialog();
  }

  void _goToNextCard(FlashcardProgressRepository repository) {
    if (_currentIndex < repository.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      _showCompletionDialog('Great job!', 'You\'ve reviewed all cards.');
    }
  }

  void _showStudyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Added to Study List'),
        content: const Text('This card will be reviewed again soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
