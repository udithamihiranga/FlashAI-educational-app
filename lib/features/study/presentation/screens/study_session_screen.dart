import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';
import 'package:flashai/features/flashcards/presentation/widgets/flashcard_widget.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';

class StudySessionScreen extends StatefulWidget {
  final StudyMode mode;
  final String? category;
  final String? noteId;
  final String? noteTitle;
  final List<Flashcard>? flashcards;

  const StudySessionScreen({
    super.key,
    required this.mode,
    this.category,
    this.noteId,
    this.noteTitle,
    this.flashcards,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late PageController _pageController;
  late List<Flashcard> _deck;
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isDone = false;
  int _cardsStudied = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _pageController = PageController();

    _deck = _buildDeck();
    if (_deck.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEmptyStateDialog();
      });
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Flashcard> _buildDeck() {
    if (widget.flashcards != null && widget.flashcards!.isNotEmpty) {
      return widget.flashcards!;
    }

    final repo = context.read<FlashcardProgressRepository>();
    final cards = repo.cards;

    switch (widget.mode) {
      case StudyMode.unreviewedOnly:
        return cards.where((c) => !c.studied).toList();
      case StudyMode.byCategory:
        return cards.where((c) => c.category == widget.category).toList();
      case StudyMode.all:
        return cards;
      case StudyMode.noteSpecific:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_deck.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          centerTitle: false,
        ),
        drawer: const AppDrawer(currentIndex: 2),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentIndex >= _deck.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          centerTitle: false,
        ),
        drawer: const AppDrawer(currentIndex: 2),
        body: Center(child: Text('No more cards to review.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(_getTitle()),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _showEndSessionDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            tooltip: 'End Session',
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 2),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            children: [
              _buildProgressHeader(theme),
              const Divider(height: 1),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _deck.length + 1,
                  onPageChanged: (index) {
                    if (index < _deck.length) {
                      setState(() {
                        _currentIndex = index;
                        _showAnswer = false;
                        _isDone = false;
                      });
                      _animationController.reset();
                      _animationController.forward();
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index < _deck.length) {
                      final card = _deck[index];
                      final isCurrent = index == _currentIndex;
                      return Center(
                        child: AnimatedOpacity(
                          opacity: isCurrent ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedScale(
                            scale: isCurrent ? 1.0 : 0.95,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: GestureDetector(
                              onDoubleTap: isCurrent && !_isDone
                                  ? () => _markAsKnown()
                                  : null,
                              onLongPress: isCurrent && !_isDone
                                  ? () => _markAsStudy()
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: FlashcardWidget(
                                  key: ValueKey<int>(index),
                                  card: card,
                                  showAnswer: isCurrent ? _showAnswer : false,
                                  onTap: isCurrent && !_isDone
                                      ? () => _toggleAnswer()
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return _buildCompletionCard(theme);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _showAnswer && !_isDone
              ? FloatingActionButton.extended(
                  onPressed: _markDone,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark as Read'),
                )
              : null,
        );
      }

  Widget _buildCompletionCard(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Great job!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve reviewed $_cardsStudied cards in this session.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    currentTabIndex.value = 2;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Back to Short Notes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme) {
    final total = _deck.length;
    final progress = total > 0 ? _cardsStudied / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentIndex + 1} of $total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_cardsStudied of $total cards are read',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case StudyMode.unreviewedOnly:
        return 'New Cards';
      case StudyMode.byCategory:
        return widget.category ?? 'Study';
      case StudyMode.noteSpecific:
        return widget.noteTitle ?? 'Study';
      case StudyMode.all:
        return 'All Flashcards';
    }
  }

  void _toggleAnswer() {
    if (_isDone) return;
    HapticFeedback.lightImpact();
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _markAsKnown() async {
    HapticFeedback.mediumImpact();
    final repo = context.read<FlashcardProgressRepository>();
    final cardId = _deck[_currentIndex].id;
    await repo.recordCorrect(cardId);
    if (!mounted) return;
    _goToNextCard();
  }

  void _markAsStudy() async {
    HapticFeedback.lightImpact();
    final repo = context.read<FlashcardProgressRepository>();
    final cardId = _deck[_currentIndex].id;
    await repo.recordIncorrect(cardId);
    if (!mounted) return;
    _showStudyDialog();
  }

  void _markDone() async {
    HapticFeedback.mediumImpact();
    try {
      final repo = context.read<FlashcardProgressRepository>();
      final cardId = _deck[_currentIndex].id;
      await repo.markAsDone(cardId);
    } catch (e) {
      print('Error marking card as done: $e');
    }
    if (!mounted) return;
    setState(() {
      _cardsStudied++;
      _isDone = true;
    });
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

  void _goToNextCard() {
    if (_currentIndex < _deck.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
      Navigator.pop(context);
      currentTabIndex.value = 2;
    }
  }

  void _showEmptyStateDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No Cards Available'),
        content: Text(_getEmptyMessage()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (widget.mode) {
      case StudyMode.unreviewedOnly:
        return 'You\'ve reviewed all new cards. Check the "All" mode for more.';
      case StudyMode.byCategory:
        return 'No flashcards in this category yet.';
      case StudyMode.noteSpecific:
        return 'This note has no flashcards.';
      case StudyMode.all:
        return 'No flashcards available. Create notes to generate flashcards.';
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Session?'),
        content: Text(
          'You\'ve referenced $_cardsStudied cards so far. Are you sure you want to end this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              currentTabIndex.value = 2;
            },
            child: Text(
              'End',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}