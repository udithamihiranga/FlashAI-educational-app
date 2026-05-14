import 'package:flutter/material.dart';

/// SectionHeader provides a standardized heading for content sections
/// Used to organize screen content with optional "See All" action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry? padding;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.padding,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 16, top: 24, right: 16, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null)
            action!
          else if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionText!,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
