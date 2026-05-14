import 'package:flutter/material.dart';
import 'package:flashai/features/flashcards/presentation/models/flashcard_model.dart';

class FlashcardWidget extends StatelessWidget {
  final Flashcard card;
  final bool showAnswer;
  final VoidCallback? onTap;

  const FlashcardWidget({
    super.key,
    required this.card,
    required this.showAnswer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    card.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 36),
                // Question
                Flexible(
                  child: Text(
                    card.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showAnswer) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  const SizedBox(height: 16),
                  // Answer
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        card.answer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.touch_app,
                    color: Colors.white70,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
