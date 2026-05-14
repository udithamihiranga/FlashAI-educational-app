import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:flashai/features/notes/presentation/widgets/note_flashcard_button.dart';
import 'package:flashai/features/study/presentation/screens/study_session_screen.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';
import 'package:provider/provider.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/features/study/presentation/screens/study_session_screen.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';

/// ShortNotesScreen displays a list of saved notes for review.
/// Users can read AI-generated summaries, study flashcards, and delete notes.
class ShortNotesScreen extends StatefulWidget {
  const ShortNotesScreen({super.key});

  @override
  State<ShortNotesScreen> createState() => _ShortNotesScreenState();
}

class _ShortNotesScreenState extends State<ShortNotesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, NotesRepository repository, SavedNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error, size: 28),
            const SizedBox(width: 12),
            const Text('Delete Note'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"? This will also remove all associated flashcards.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await repository.deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note deleted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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
        title: const Text('Short Notes'),
        centerTitle: false,
      ),
      drawer: const AppDrawer(currentIndex: 2),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Consumer<NotesRepository>(
            builder: (context, repository, child) {
              final notesWithFlashcards = repository.notes
                  .where((note) => note.flashcards.isNotEmpty)
                  .toList();

              if (notesWithFlashcards.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No notes with flashcards yet',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create notes from the Notes tab and generate flashcards to start learning.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notesWithFlashcards.length,
                itemBuilder: (context, index) {
                  final note = notesWithFlashcards[index];
                  return _NoteCard(
                    note: note,
                    onDelete: () => _confirmDelete(context, repository, note),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final SavedNote note;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masteryLevel = _getMasteryLevel(note);
    final masteryColor = _getMasteryColor(masteryLevel, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Mastery icon
                 Container(
                   width: 50,
                   height: 50,
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       colors: [
                         masteryColor,
                         masteryColor.withOpacity(0.7),
                       ],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ),
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                       BoxShadow(
                         color: masteryColor.withOpacity(0.25),
                         blurRadius: 8,
                         offset: const Offset(0, 3),
                       ),
                     ],
                   ),
                   child: Icon(
                     Icons.school_rounded,
                     color: Colors.white,
                     size: 20,
                   ),
                 ),
                const SizedBox(width: 12),
                // Title and meta info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildChip(
                            theme,
                            label: '${note.flashcards.length} cards',
                            icon: Icons.style_rounded,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Note content preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openNoteDetail(context, note),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Read'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                        onPressed: note.flashcards.isNotEmpty
                            ? () {
                                HapticFeedback.mediumImpact();
                                NavigationService.pushPage(
                                  builder: (context) => StudySessionScreen(
                                    mode: StudyMode.noteSpecific,
                                    noteId: note.id,
                                    noteTitle: note.title,
                                    flashcards: note.flashcards,
                                  ),
                                  routeName: AppRoutes.studySession,
                                  tabIndex: 2, // Study tab (ShortNotes is under Study)
                                  settings: RouteSettings(arguments: {
                                    'mode': StudyMode.noteSpecific,
                                    'noteId': note.id,
                                    'noteTitle': note.title,
                                    'flashcards': note.flashcards,
                                  }),
                                );
                              }
                            : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Study'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme,
      {required String label, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getMasteryLevel(SavedNote note) {
    if (note.masteryLog == null || note.masteryLog!.topics.isEmpty) {
      return 'Not started';
    }
    final mastered = note.masteryLog!.masteredCount;
    final total = note.masteryLog!.topics.length;
    final progress = mastered / total;
    if (progress >= 0.8) return 'Mastered';
    if (progress >= 0.5) return 'In Progress';
    if (progress > 0) return 'Beginning';
    return 'Learning';
  }

  Color _getMasteryColor(String level, ThemeData theme) {
    switch (level) {
      case 'Mastered':
        return Colors.green;
      case 'In Progress':
        return theme.colorScheme.primary;
      case 'Beginning':
        return Colors.orange;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }

  void _openNoteDetail(BuildContext context, SavedNote note) {
    NavigationService.pushPage(
      builder: (context) => _NoteDetailScreen(note: note),
      routeName: AppRoutes.noteDetail,
      tabIndex: 2, // This screen is part of Study tab
      settings: RouteSettings(arguments: {'note': note}),
    );
  }
}

class _NoteDetailScreen extends StatelessWidget {
  final SavedNote note;

  const _NoteDetailScreen({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Short Note'),
          centerTitle: false,
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
               const SizedBox(height: 16),
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.surface,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(
                     color: theme.colorScheme.outline.withOpacity(0.2),
                   ),
                 ),
                 child: MarkdownBody(
                   data: note.content,
                   styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                     p: theme.textTheme.bodyLarge?.copyWith(
                       height: 1.7,
                       color: theme.colorScheme.onSurface,
                     ),
                     h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                     h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                     h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                     blockquote: theme.textTheme.bodyMedium?.copyWith(
                       color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 32),
              if (note.flashcards.isNotEmpty) ...[
                Text(
                  'Flashcards (${note.flashcards.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...note.flashcards.map((card) => _FlashcardPreviewCard(card: card)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  NavigationService.pushPage(
                    builder: (context) => StudySessionScreen(
                      mode: StudyMode.noteSpecific,
                      noteId: note.id,
                      noteTitle: note.title,
                      flashcards: note.flashcards,
                    ),
                    routeName: AppRoutes.studySession,
                    tabIndex: 2, // Study tab
                    settings: RouteSettings(arguments: {
                      'mode': StudyMode.noteSpecific,
                      'noteId': note.id,
                      'noteTitle': note.title,
                      'flashcards': note.flashcards,
                    }),
                  );
                },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Studying'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No flashcards generated for this note yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlashcardPreviewCard extends StatelessWidget {
  final Flashcard card;

  const _FlashcardPreviewCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            card.type == FlashcardType.cloze ? Icons.label_important_rounded : Icons.question_answer_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          card.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            card.answer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
