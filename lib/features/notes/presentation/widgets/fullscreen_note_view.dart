import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/study/presentation/screens/study_session_screen.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';

class FullscreenNoteView extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final SavedNote? note;

  const FullscreenNoteView({
    super.key,
    required this.title,
    required this.content,
    required this.onClose,
    this.onSave,
    this.note,
  });

  @override
  State<FullscreenNoteView> createState() => _FullscreenNoteViewState();
}

class _FullscreenNoteViewState extends State<FullscreenNoteView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
    
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyEvent);
    _animationController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return true;
    }
    return false;
  }

  void _handleSave() {
    HapticFeedback.lightImpact();
    if (widget.onSave != null) {
      widget.onSave!();
    } else {
      widget.onClose();
    }
  }

  void _showFlashcardDialog() {
    HapticFeedback.lightImpact();
    if (widget.note == null || widget.note!.flashcards.isEmpty) return;
    NavigationService.pushPage(
      builder: (context) => StudySessionScreen(
        mode: StudyMode.noteSpecific,
        noteId: widget.note!.id,
        noteTitle: widget.note!.title,
        flashcards: widget.note!.flashcards,
      ),
      routeName: AppRoutes.studySession,
      tabIndex: 1, // Notes tab (fullscreen view likely in Notes)
      settings: RouteSettings(arguments: {
        'mode': StudyMode.noteSpecific,
        'noteId': widget.note!.id,
        'noteTitle': widget.note!.title,
        'flashcards': widget.note!.flashcards,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final titleColor = isDark ? Colors.white : theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: GestureDetector(
          onTap: widget.onClose,
          behavior: HitTestBehavior.translucent,
          child: Container(
            color: backgroundColor,
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar with close button
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.title.isNotEmpty)
                            Expanded(
                              child: Text(
                                widget.title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                          if (widget.note != null && widget.note!.flashcards.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _showFlashcardDialog,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.style_rounded,
                                          size: 20,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.note!.flashcards.length}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleSave,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.save_rounded,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Save',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onClose,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 24,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                   // Content area
                   Expanded(
                     child: SingleChildScrollView(
                       padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                       child: SlideTransition(
                         position: _slideAnimation,
                         child: Container(
                           constraints: const BoxConstraints(maxWidth: 800),
                           alignment: Alignment.topCenter,
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               MarkdownBody(
                                 data: widget.content,
                                 styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                   p: theme.textTheme.bodyLarge?.copyWith(
                                     fontSize: 18,
                                     height: 1.7,
                                     color: isDark ? Colors.white70 : Colors.black87,
                                   ),
                                   h1: theme.textTheme.headlineMedium?.copyWith(
                                     fontWeight: FontWeight.bold,
                                     color: titleColor,
                                   ),
                                   h2: theme.textTheme.titleLarge?.copyWith(
                                     fontWeight: FontWeight.w700,
                                     color: titleColor,
                                   ),
                                   h3: theme.textTheme.titleMedium?.copyWith(
                                     fontWeight: FontWeight.w600,
                                   ),
                                   blockquote: theme.textTheme.bodyMedium?.copyWith(
                                     color: isDark ? Colors.white60 : Colors.black54,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Old dialog removed - using StudySessionScreen instead
