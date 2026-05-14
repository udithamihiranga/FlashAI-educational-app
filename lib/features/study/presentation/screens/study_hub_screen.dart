import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';
import 'package:flashai/features/study/presentation/screens/short_notes_screen.dart';
import 'package:flashai/features/study/presentation/screens/study_session_screen.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';

/// StudyHub is a focused study command center.
/// Shows key metrics and quick access to study sessions.
class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideInAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      drawer: const AppDrawer(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(theme),
                const SizedBox(height: 40),
                _buildStatsSection(theme),
                const SizedBox(height: 36),
                _buildActionSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Scaffold.of(context).openDrawer();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
      title: const Text('Study Hub'),
      centerTitle: true,
    );
  }

  Widget _buildHero(ThemeData theme) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return SlideTransition(
      position: _slideInAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ready to learn something new?',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Consumer<FlashcardProgressRepository>(
      builder: (context, repo, child) {
        final totalCards = repo.totalCards;
        final masteredCards = repo.masteredCount;
        final todayReviewed = _getTodayReviewedCount(repo);
        final streak = _calculateStreak(repo);

        final hasStats = totalCards > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Day Streak',
                    color: Colors.orange,
                    theme: theme,
                    isActive: hasStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.style_rounded,
                    value: hasStats ? '$masteredCards' : '0',
                    label: 'Mastered',
                    color: Colors.green,
                    theme: theme,
                    isActive: hasStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.today_rounded,
                    value: '$todayReviewed',
                    label: 'Studied Today',
                    color: theme.colorScheme.primary,
                    theme: theme,
                    isActive: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionSection(ThemeData theme) {
    return Consumer<FlashcardProgressRepository>(
      builder: (context, repo, child) {
        final newCount = repo.unreviewedCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Study',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
             _ActionCard(
               icon: Icons.school_rounded,
               title: 'Study New Cards',
               description: newCount > 0
                   ? '$newCount unreviewed card${newCount == 1 ? '' : 's'} waiting'
                   : 'All cards reviewed — great job!',
               color: theme.colorScheme.primary,
               theme: theme,
               enabled: newCount > 0,
                        onTap: newCount > 0
                            ? () {
                                HapticFeedback.mediumImpact();
                                NavigationService.pushPage(
                                  builder: (context) => StudySessionScreen(
                                    mode: StudyMode.unreviewedOnly,
                                  ),
                                  routeName: AppRoutes.studySession,
                                  tabIndex: 2, // Study tab
                                  settings: RouteSettings(arguments: {'mode': StudyMode.unreviewedOnly}),
                                );
                              }
                            : null,
             ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.menu_book_rounded,
              title: 'Short Notes',
              description: 'Review AI-generated summaries',
              color: Colors.purple,
              theme: theme,
              enabled: true,
              onTap: () {
                HapticFeedback.lightImpact();
                NavigationService.pushPage(
                  builder: (context) => const ShortNotesScreen(),
                  routeName: AppRoutes.shortNotes,
                  tabIndex: 2, // Study tab
                );
              },
            ),
          ],
        );
      },
    );
  }

  int _getTodayReviewedCount(FlashcardProgressRepository repo) {
    final today = DateTime.now();
    return repo.cards
        .where((c) =>
            c.lastReviewed != null &&
            c.lastReviewed!.year == today.year &&
            c.lastReviewed!.month == today.month &&
            c.lastReviewed!.day == today.day)
        .length;
  }

  int _calculateStreak(FlashcardProgressRepository repo) {
    int streak = 0;
    DateTime date = DateTime.now();
    while (true) {
      final hasReview = repo.cards.any((c) =>
          c.lastReviewed != null &&
          c.lastReviewed!.year == date.year &&
          c.lastReviewed!.month == date.month &&
          c.lastReviewed!.day == date.day);
      if (hasReview) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ThemeData theme;
  final bool isActive;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final ThemeData theme;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.theme,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: enabled ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? theme.colorScheme.outline.withValues(alpha: 0.12)
                  : theme.colorScheme.outline.withValues(alpha: 0.06),
            ),
            boxShadow: enabled ? [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: enabled
                        ? [color, color.withOpacity(0.7)]
                        : [theme.colorScheme.onSurface.withValues(alpha: 0.08), theme.colorScheme.onSurface.withValues(alpha: 0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: enabled ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
