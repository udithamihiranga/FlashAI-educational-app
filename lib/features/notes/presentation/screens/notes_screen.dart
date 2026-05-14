import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flashai/shared/widgets/app_text_field.dart';
import 'package:flashai/shared/widgets/custom_button.dart';
import 'package:flashai/shared/widgets/section_header.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/features/notes/presentation/models/note_file.dart';
import 'package:flashai/features/notes/presentation/services/pdf_service.dart';
import 'package:flashai/features/notes/presentation/widgets/fullscreen_note_view.dart';
import 'package:flashai/features/notes/presentation/services/ai_service.dart';
import 'package:flashai/features/notes/presentation/models/saved_note.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';
import 'package:flashai/services/push/push_notification_service.dart';
import 'package:flashai/features/notifications/presentation/models/notification_model.dart';
import 'package:provider/provider.dart';
/// NotesScreen allows creating and previewing AI-generated notes
/// Supports multi-modal input: text entry or PDF file attachments
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();
  bool _isGenerating = false;
  bool _hasGenerated = false;
  bool _isFullscreen = false;

  // Attached PDF files
  final List<NoteFile> _attachedFiles = [];

  // Generated content
  String _generatedContent = '';
  List<Flashcard> _generatedFlashcards = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentScrollController.dispose();
    _previewScrollController.dispose();
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
        title: const Text('Create Notes'),
        actions: [
          if (_hasGenerated)
            IconButton(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy to clipboard',
            ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 1),
      body: SafeArea(
        child: Stack(
          children: [
            if (!_isFullscreen)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputSection(theme),
                      const SizedBox(height: 16),
                      _buildGenerateButton(theme),
                      const SizedBox(height: 24),
                      _hasGenerated
                          ? _buildPreviewSection(theme)
                          : _buildEmptyPreview(theme),
                    ],
                  ),
                ),
              ),
            if (_isFullscreen)
              _buildFullscreenPreview(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Your Notes',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Title field
        AppTextField(
          labelText: 'Title',
          hintText: 'Enter a title for your notes',
          controller: _titleController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          prefixIcon: Icons.title_rounded,
        ),
        const SizedBox(height: 16),
        // Content field with file attachment suffix
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                    Expanded(
                      child: Scrollbar(
                        controller: _contentScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        child: SingleChildScrollView(
                          controller: _contentScrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            minLines: null,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter or paste your raw content here...\n\nOR attach PDF files using the button below.',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: _attachPDF,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Attach PDF',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                  ),
                 ),
               ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Attached files list
            if (_attachedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAttachedFilesList(theme),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAttachedFilesList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached PDFs:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachedFiles.map((file) => _buildFileChip(theme, file)).toList(),
        ),
      ],
    );
  }

  Widget _buildFileChip(ThemeData theme, NoteFile file) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 6),
          Text(
            file.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 4),
          if (file.isProcessing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: () => _removeFile(file.id),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isGenerating ? 'Generating...' : 'Generate Notes & Flashcards',
        icon: Icons.auto_awesome_rounded,
        onPressed: _isGenerating ? null : _generateNotes,
        isLoading: _isGenerating,
      ),
    );
  }

  Widget _buildEmptyPreview(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Generated notes will appear here',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the title and add content (text or PDF), then tap Generate',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenPreview(ThemeData theme) {
    final repository = Provider.of<NotesRepository>(context, listen: false);
    final existingNote = repository.notes.firstWhere(
          (note) => note.title == _titleController.text && note.content == _generatedContent,
          orElse: () => SavedNote(title: _titleController.text, content: _generatedContent),
        );

    return FullscreenNoteView(
      title: _titleController.text,
      content: _generatedContent,
      onClose: () {
        setState(() {
          _isFullscreen = false;
        });
      },
      onSave: () async {
        HapticFeedback.lightImpact();
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving note...'),
              duration: Duration(milliseconds: 500),
            ),
          );
          final note = await repository.saveNote(
            title: _titleController.text,
            content: _generatedContent,
            generateFlashcards: true,
          );
          if (note != null && mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Note "${_titleController.text}" saved successfully'),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to save note'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        setState(() {
          _isFullscreen = false;
        });
      },
      note: existingNote,
    );
  }

Widget _buildPreviewSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Generated Output',
          padding: EdgeInsets.zero,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _hasGenerated ? _saveGeneratedNote : null,
                icon: Icon(
                  Icons.save_rounded,
                  color: _hasGenerated
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                tooltip: 'Save note',
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isFullscreen = !_isFullscreen;
                  });
                },
                icon: Icon(
                  _isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  color: theme.colorScheme.primary,
                ),
                tooltip: _isFullscreen ? 'Exit fullscreen' : 'View in fullscreen',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Fixed-size content box with internal scroll
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_titleController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _titleController.text,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
             Expanded(
               child: Scrollbar(
                 controller: _previewScrollController,
                 thumbVisibility: true,
                 trackVisibility: true,
                 interactive: true,
                 child: SingleChildScrollView(
                   controller: _previewScrollController,
                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                   child: MarkdownBody(
                     data: _generatedContent,
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
                 ),
               ),
             ),
             ],
           ),
         ),
       ],
     );
   }

  /// Attach a PDF file using file picker
  Future<void> _attachPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        for (var pickedFile in result.files) {
          final file = NoteFile(
            id: DateTime.now().millisecondsSinceEpoch.toString() + pickedFile.name,
            name: pickedFile.name,
            path: pickedFile.path!,
            size: pickedFile.size,
            isProcessing: false,
          );
          _attachedFiles.add(file);
        }
      });

      // Start extracting text from newly added files
      _extractPDFTexts();
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  /// Remove a file from the attached list
  void _removeFile(String fileId) {
    setState(() {
      _attachedFiles.removeWhere((f) => f.id == fileId);
    });
  }

  /// Extract text from all attached PDFs
  Future<void> _extractPDFTexts() async {
    for (var file in _attachedFiles) {
      if (file.extractedText != null) continue;

      setState(() {
        // Mark file as processing
        int index = _attachedFiles.indexWhere((f) => f.id == file.id);
        if (index != -1) {
          _attachedFiles[index] = file.copyWith(isProcessing: true);
        }
      });

      try {
        final extractedText = await PDFService.extractText(file.path);

        setState(() {
          int index = _attachedFiles.indexWhere((f) => f.id == file.id);
          if (index != -1) {
            _attachedFiles[index] = file.copyWith(
              extractedText: extractedText,
              isProcessing: false,
            );
          }
        });
      } catch (e) {
        setState(() {
          int index = _attachedFiles.indexWhere((f) => f.id == file.id);
          if (index != -1) {
            _attachedFiles[index] = file.copyWith(isProcessing: false);
          }
        });
        _showErrorSnackBar('Failed to extract text from ${file.name}: $e');
      }
    }
  }

  /// Validate and generate notes
  Future<void> _generateNotes() async {
    // Validate title
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return;
    }

    // Validate: either text content or PDF files with extracted text
    final hasTextContent = _contentController.text.trim().isNotEmpty;
    final hasPDFsWithText = _attachedFiles.any((f) => f.extractedText != null && f.extractedText!.isNotEmpty);

    if (!hasTextContent && !hasPDFsWithText) {
      _showErrorSnackBar('Please enter text content or attach at least one PDF with extractable text');
      return;
    }

    // Wait for any ongoing PDF extraction
    bool anyProcessing = _attachedFiles.any((f) => f.isProcessing);
    if (anyProcessing) {
      _showErrorSnackBar('Please wait for PDFs to finish processing');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Combine all content sources
      final StringBuffer combinedContent = StringBuffer();

      if (hasTextContent) {
        combinedContent.writeln('--- Manual Text Input ---');
        combinedContent.writeln(_contentController.text.trim());
        combinedContent.writeln();
      }

      if (hasPDFsWithText) {
        for (var file in _attachedFiles) {
          if (file.extractedText != null && file.extractedText!.isNotEmpty) {
            combinedContent.writeln('--- From PDF: ${file.name} ---');
            combinedContent.writeln(file.extractedText);
            combinedContent.writeln();
          }
        }
      }

// Generate notes using AI service
        final studyMaterial = await AIService.generateStudyMaterial(
          title: _titleController.text.trim(),
          content: combinedContent.toString(),
        );

setState(() {
           _generatedContent = studyMaterial.notes;
           _generatedFlashcards = studyMaterial.flashcards;
           _isGenerating = false;
           _hasGenerated = true;
         });

        HapticFeedback.mediumImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notes generated for "${_titleController.text}"'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Send push notification that generation is complete
        try {
          final pushService = PushNotificationService();
          if (pushService.isInitialized) {
            pushService.showNotification(NotificationItem(
              id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Generation Complete',
              body: 'Your notes for "${_titleController.text}" are ready!',
              timestamp: DateTime.now(),
            ));
          }
        } catch (e) {
          // Silently ignore notification errors
          debugPrint('Failed to send generation notification: $e');
        }
     } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showErrorSnackBar('Failed to generate notes: $e');
    }
  }

  void _copyToClipboard() {
    final content = '${_titleController.text}\n\n$_generatedContent';
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveGeneratedNote() async {
    final theme = Theme.of(context);
    final repository = Provider.of<NotesRepository>(context, listen: false);

    HapticFeedback.lightImpact();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving note...'),
          duration: Duration(milliseconds: 500),
        ),
      );
      final note = await repository.saveGeneratedNote(
        title: _titleController.text,
        content: _generatedContent,
        flashcards: _generatedFlashcards,
      );
      if (note != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note "${_titleController.text}" saved successfully'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save note'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

