import 'package:flutter/material.dart';

/// CustomButton is a versatile button component supporting primary and secondary styles
/// Follows FlashAI design system with rounded corners and gradient support
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: isEnabled ? Colors.white : Colors.white54)
        else
          const SizedBox.shrink(),
        if (icon != null && !isLoading) const SizedBox(width: 8),
        if (isLoading)
          const SizedBox(width: 8)
        else
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isEnabled ? Colors.white : Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    Widget button = isSecondary
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size(width ?? double.infinity, height),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: buttonContent,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size(width ?? double.infinity, height),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: buttonContent,
          );

    return button;
  }
}
