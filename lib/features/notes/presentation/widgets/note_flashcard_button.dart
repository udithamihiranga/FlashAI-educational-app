import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/study/presentation/screens/study_session_screen.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';

/// A button that navigates to a full-screen study session for the given note's flashcards.
class NoteFlashcardButton extends StatelessWidget {
  final SavedNote note;

  const NoteFlashcardButton({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flashcardCount = note.flashcards.length;

    if (flashcardCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          NavigationService.pushPage(
            builder: (context) => StudySessionScreen(
              mode: StudyMode.noteSpecific,
              noteId: note.id,
              noteTitle: note.title,
              flashcards: note.flashcards,
            ),
            routeName: AppRoutes.studySession,
            tabIndex: 1, // Notes tab (button is in Notes screen)
            settings: RouteSettings(arguments: {
              'mode': StudyMode.noteSpecific,
              'noteId': note.id,
              'noteTitle': note.title,
              'flashcards': note.flashcards,
            }),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
          foregroundColor: theme.colorScheme.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.secondary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: theme.colorScheme.secondary,
            size: 22,
          ),
        ),
        label: Text(
          'Study ${flashcardCount} Flashcard${flashcardCount > 1 ? 's' : ''}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
