import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:provider/provider.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesRepository>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Notes'),
      ),
      body: Consumer<NotesRepository>(
        builder: (context, repository, child) {
          if (repository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (repository.notes.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: repository.notes.length,
            itemBuilder: (context, index) {
              final note = repository.notes[index];
              return Dismissible(
              key: Key('note_${note.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: Icon(
                  Icons.delete_rounded,
                  color: theme.colorScheme.error,
                  size: 32,
                ),
              ),
              confirmDismiss: (direction) async {
                HapticFeedback.lightImpact();
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Delete Note',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete "${note.title}"?\nThis action cannot be undone.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              child: _buildNoteCard(theme, note),
            );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_rounded,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved notes yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create notes in the Notes tab to see them here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(ThemeData theme, SavedNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              note.title,
              style: theme.textTheme.titleMedium?.copyWith(
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 14,
                      color: note.flashcards.isNotEmpty
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.flashcardCountLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: note.flashcards.isNotEmpty
                            ? theme.colorScheme.secondary.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              NavigationService.pushPage(
                builder: (context) => NoteDetailScreen(noteId: note.id),
                routeName: AppRoutes.noteDetail,
                tabIndex: 1, // Notes tab origin
              );
            },
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteDetailScreen extends StatelessWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  Future<void> _deleteNote(BuildContext context) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Note',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note?\nThis action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      final deleted = await context.read<NotesRepository>().deleteNote(noteId);
      if (deleted && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note deleted'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
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
        title: const Text('Note Details'),
        actions: [
          IconButton(
            onPressed: () => _deleteNote(context),
            icon: const Icon(Icons.delete_rounded),
            color: theme.colorScheme.error,
            tooltip: 'Delete note',
          ),
        ],
      ),
      body: FutureBuilder<SavedNote?>(
        future: context.read<NotesRepository>().getNoteById(noteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Note not found',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final note = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                 const SizedBox(height: 24),
                 MarkdownBody(
                   data: note.content,
                   styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                     p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                     h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                     h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                     h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                     blockquote: theme.textTheme.bodyMedium?.copyWith(
                       color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                     ),
                   ),
                 ),
                  const SizedBox(height: 24),
               ],
            ),
          );
        },
      ),
    );
  }
}
