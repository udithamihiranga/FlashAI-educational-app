import 'package:flutter/material.dart';

/// AppTextField is a custom TextFormField styled according to FlashAI design system
/// Supports both single-line and multi-line inputs with Material 3 styling
class AppTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      keyboardType: keyboardType ?? (maxLines != 1 ? TextInputType.multiline : TextInputType.text),
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, size: 20),
              )
            : null,
      ),
    );
  }
}
