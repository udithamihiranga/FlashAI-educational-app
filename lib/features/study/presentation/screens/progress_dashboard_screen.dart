import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';

/// ProgressDashboardScreen displays detailed learning analytics and achievements.
/// It motivates users with streaks, accuracy trends, and mastery breakdown.
class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

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
    _animationController.forward();
    
    // Load flashcard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FlashcardProgressRepository>().loadCards();
      }
    });
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
        title: const Text('Progress Dashboard'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(currentIndex: 2),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStreakSection(theme),
                const SizedBox(height: 24),
                _buildOverviewCards(theme),
                const SizedBox(height: 24),
                _buildMasteryByCategory(theme),
                const SizedBox(height: 24),
                _buildAchievements(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection(ThemeData theme) {
    return Consumer<FlashcardProgressRepository>(
      builder: (context, repo, _) {
        final streak = _calculateStreak(repo);
        final todayCount = _getTodayReviewedCount(repo);
        final bestStreak = _getBestStreak(repo);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Learning Streak',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: _StreakCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    label: 'Current Streak',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _StreakCard(
                    icon: Icons.trending_up_rounded,
                    value: '$todayCount',
                    label: 'Studied Today',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _StreakCard(
                    icon: Icons.emoji_events_rounded,
                    value: '$bestStreak',
                    label: 'Best Streak',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCards(ThemeData theme) {
    return Consumer<FlashcardProgressRepository>(
      builder: (context, repo, _) {
        final total = repo.totalCards;
        final mastered = repo.masteredCount;
        final reviewed = repo.reviewedCount;
        final accuracy = total > 0
            ? repo.cards.fold<int>(0, (sum, c) => sum + c.correctCount) /
                (repo.cards.fold<int>(0, (sum, c) => sum + c.correctCount + c.incorrectCount))
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  title: 'Total Cards',
                  value: total.toString(),
                  icon: Icons.style_rounded,
                  color: theme.colorScheme.primary,
                ),
                _StatCard(
                  title: 'Mastered',
                  value: mastered.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Reviewed',
                  value: reviewed.toString(),
                  icon: Icons.visibility_rounded,
                  color: theme.colorScheme.secondary,
                ),
                _StatCard(
                  title: 'Accuracy',
                  value: '${(accuracy * 100).toStringAsFixed(1)}%',
                  icon: Icons.bar_chart_rounded,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMasteryByCategory(ThemeData theme) {
    return Consumer<FlashcardProgressRepository>(
      builder: (context, repo, _) {
        final Map<String, int> categoryTotals = {};
        final Map<String, int> categoryStudied = {};

        for (final card in repo.cards) {
          final cat = card.category;
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + 1;
          // Consider a card "studied" if it has been reviewed at least once
          if (card.studied || card.correctCount > 0 || card.incorrectCount > 0) {
            categoryStudied[cat] = (categoryStudied[cat] ?? 0) + 1;
          }
        }

        if (categoryTotals.isEmpty) {
          return const SizedBox.shrink();
        }

        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                   'Progress by Category',
                   style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                 ),
                 Text(
                   '${categoryTotals.values.fold<int>(0, (a, b) => a + b)} total cards',
                   style: theme.textTheme.bodySmall?.copyWith(
                     color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             ...sortedCategories
                 .take(5)
                 .map(
                   (entry) => Padding(
                     padding: const EdgeInsets.only(bottom: 16),
                     child: _CategoryProgressBar(
                       category: entry.key,
                       total: entry.value,
                       studied: categoryStudied[entry.key] ?? 0,
                     ),
                   ),
                 )
                 .toList(),
           ],
         );
      },
    );
  }

  Widget _buildAchievements(ThemeData theme) {
    // Placeholder achievements - could be dynamic based on user activity
    final achievements = [
      _Achievement(
        icon: Icons.offline_pin_rounded,
        title: 'First Steps',
        description: 'Study your first flashcard',
        unlocked: true,
      ),
      _Achievement(
        icon: Icons.local_fire_department_rounded,
        title: 'On Fire',
        description: 'Maintain a 3-day streak',
        unlocked: true,
      ),
      _Achievement(
        icon: Icons.psychology_rounded,
        title: 'Memory Master',
        description: 'Master 10 flashcards',
        unlocked: false,
      ),
      _Achievement(
        icon: Icons.school_rounded,
        title: 'Scholar',
        description: 'Complete 50 study sessions',
        unlocked: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: achievements
              .map(
                (a) => _AchievementCard(achievement: a),
              )
              .toList(),
        ),
      ],
    );
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

  int _getTodayReviewedCount(FlashcardProgressRepository repo) {
    final today = DateTime.now();
    return repo.cards
        .where((c) => c.lastReviewed != null &&
            c.lastReviewed!.year == today.year &&
            c.lastReviewed!.month == today.month &&
            c.lastReviewed!.day == today.day)
        .length;
  }

  int _getBestStreak(FlashcardProgressRepository repo) {
    // Simplified: returns current streak; could compute historical best if stored
    return _calculateStreak(repo);
  }
}

class _StreakCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StreakCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProgressBar extends StatelessWidget {
  final String category;
  final int total;
  final int studied;

  const _CategoryProgressBar({
    required this.category,
    required this.total,
    required this.studied,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? studied / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$studied / $total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.7
                  ? Colors.green
                  : progress >= 0.4
                      ? theme.colorScheme.primary
                      : Colors.orange,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
   }
}

class _Achievement {
  final IconData icon;
  final String title;
  final String description;
  final bool unlocked;

  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achievement.unlocked
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            color: achievement.unlocked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.4),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: achievement.unlocked
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
