import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/shared/widgets/section_header.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:flashai/features/notes/presentation/screens/saved_notes_screen.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';
import 'package:flashai/features/study/presentation/screens/progress_dashboard_screen.dart';
import 'package:flashai/features/auth/presentation/providers/auth_provider.dart';
import 'package:flashai/features/auth/data/firebase_auth_service.dart';

/// DashboardScreen displays the main overview with analytics and quick actions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideInAnimation;

  bool _showAllSubjects = false;

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
    _slideInAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getSubjectData(
    NotesRepository notesRepo,
    FlashcardProgressRepository progressRepo,
  ) {
    final categoryMap = <String, List<Flashcard>>{};
    final categoryNoteMap = <String, String?>{};

    // Get all tracked flashcards from progress repository (real-time data)
    final allCards = progressRepo.cards;

    for (final card in allCards) {
      categoryMap.putIfAbsent(card.category, () => []).add(card);
      // Find the note ID for this category
      if (categoryNoteMap[card.category] == null) {
        for (final note in notesRepo.notes) {
          if (note.flashcards.any((fc) => fc.category == card.category)) {
            categoryNoteMap[card.category] = note.id;
            break;
          }
        }
      }
    }

    if (categoryMap.isEmpty) {
      return [];
    }

    return categoryMap.entries.map((entry) {
      final List<Flashcard> cards = entry.value;
      final totalCards = cards.length;
      final studiedCount = cards
          .where(
            (card) =>
                card.studied ||
                card.correctCount > 0 ||
                card.incorrectCount > 0,
          )
          .length;

      return {
        'name': entry.key,
        'totalCards': totalCards,
        'studiedCount': studiedCount,
        'noteId': categoryNoteMap[entry.key],
      };
    }).toList()..sort(
      (a, b) => (b['totalCards'] as int).compareTo((a['totalCards'] as int)),
    );
  }

  Widget _buildSubjectProgressCard(
    String subjectName,
    int totalCards,
    int studiedCount,
    ThemeData theme,
  ) {
    final double progress = totalCards > 0 ? studiedCount / totalCards : 0.0;
    final icons = {
      'Biology': Icons.biotech_rounded,
      'Chemistry': Icons.science_rounded,
      'Mathematics': Icons.calculate_rounded,
      'Language': Icons.language_rounded,
      'Physics': Icons.speed_rounded,
      'History': Icons.history_rounded,
      'Literature': Icons.menu_book_rounded,
    };
    final icon = icons[subjectName] ?? Icons.school_rounded;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.primary.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCards == 0
                        ? 'No cards yet'
                        : '$studiedCount of $totalCards reviewed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (totalCards > 0)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openNoteForSubject(
    BuildContext context,
    String? noteId,
    String subjectName,
  ) {
    if (noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No notes available for $subjectName yet'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    NavigationService.pushPage(
      builder: (context) => NoteDetailScreen(noteId: noteId),
      routeName: AppRoutes.noteDetail,
      tabIndex: 0, // Dashboard tab origin
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      drawer: const AppDrawer(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 28),
                Consumer2<NotesRepository, FlashcardProgressRepository>(
                  builder: (context, notesRepo, progressRepo, child) {
                    final subjectData = _getSubjectData(
                      notesRepo,
                      progressRepo,
                    );

                    if (subjectData.isEmpty) {
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.08),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Create notes to start tracking your progress',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ),
                        ),
                      );
                    }

                    final displayedSubjects = _showAllSubjects
                        ? subjectData
                        : subjectData.take(2).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Your Stats',
                          actionText: subjectData.length > 2 ? 'See All' : null,
                          onActionTap: subjectData.length > 2
                              ? () {
                                  setState(() {
                                    _showAllSubjects = !_showAllSubjects;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),
                        for (final subject in displayedSubjects)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                final String name = subject['name'];
                                final String? noteId = subject['noteId'];
                                _openNoteForSubject(context, noteId, name);
                              },
                              child: _buildSubjectProgressCard(
                                subject['name'],
                                subject['totalCards'],
                                subject['studiedCount'],
                                theme,
                              ),
                            ),
                          ),
                        if (_showAllSubjects && subjectData.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAllSubjects = false;
                                });
                              },
                              child: const Text('See Less'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                _buildQuickActionsSection(theme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final authProvider = context.watch<AuthProvider?>();
    final firebaseUser = FirebaseAuthService().currentUser;
    final userPhotoURL = firebaseUser?.photoURL;
    final userName =
        authProvider?.userName ?? firebaseUser?.displayName ?? 'Student';
    final initials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : 'U';

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
            child: Icon(Icons.menu_rounded, size: 20, color: Colors.white),
          ),
        ),
      ),
      title: const Text('Dashboard'),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed(AppRoutes.editProfile);
          },
          icon: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(255, 237, 223, 223),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ClipOval(
                child: userPhotoURL != null
                    ? Image.network(
                        userPhotoURL,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsAvatar(theme, initials);
                        },
                      )
                    : _buildInitialsAvatar(theme, initials),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(ThemeData theme, String initials) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final userName = context.watch<AuthProvider?>()?.userName ?? 'Student';

    return SlideTransition(
      position: _slideInAnimation,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let\'s keep learning!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Quick Actions', padding: EdgeInsets.zero),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: 'Create Notes',
                description: 'Generate AI notes',
                icon: Icons.edit_rounded,
                iconColor: theme.colorScheme.primary,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Switch to Notes tab with root entry in stack
                  NavigationService.stackManager.pushRoute(
                    AppRoutes.notes,
                    tabIndex: 1,
                    arguments: null,
                  );
                  currentTabIndex.value = 1;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionCard(
                title: 'Start Flashcards',
                description: 'Review deck',
                icon: Icons.flash_on_rounded,
                iconColor: theme.colorScheme.secondary,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Switch to Study tab with root entry in stack
                  NavigationService.stackManager.pushRoute(
                    AppRoutes.studyHub,
                    tabIndex: 2,
                    arguments: null,
                  );
                  currentTabIndex.value = 2;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionCard(
          title: 'View Progress',
          description: 'See your learning analytics',
          icon: Icons.insights_rounded,
          iconColor: Colors.teal,
          gradient: const LinearGradient(
            colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            NavigationService.pushPage(
              builder: (context) => const ProgressDashboardScreen(),
              routeName: AppRoutes.progressDashboard,
              tabIndex: 0,
            );
          },
        ),
      ],
    );
  }
}

/// _ActionCard is a tappable card for dashboard quick actions
class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SavedNotesBottomSheet extends StatelessWidget {
  const SavedNotesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: 'Recent Notes',
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<NotesRepository>(
              builder: (context, repository, child) {
                if (repository.notes.isEmpty) {
                  return Center(
                    child: Text(
                      'No notes yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: repository.notes.length,
                  itemBuilder: (context, index) {
                    final note = repository.notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              note.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (note.flashcards.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.style_rounded,
                                      size: 14,
                                      color: theme.colorScheme.secondary
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${note.flashcards.length} flashcard${note.flashcards.length > 1 ? 's' : ''}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop(); // Dismiss any dialog
                          NavigationService.pushPage(
                            builder: (context) =>
                                NoteDetailScreen(noteId: note.id),
                            routeName: AppRoutes.noteDetail,
                            tabIndex: 0, // Dashboard tab (origin)
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
