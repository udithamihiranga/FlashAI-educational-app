import 'package:flutter/material.dart';

/// Reusable Auth Divider Widget with OR text
class AuthDivider extends StatelessWidget {
  final String text;
  final Color dividerColor;
  final Color textColor;

  const AuthDivider({
    Key? key,
    this.text = 'OR',
    this.dividerColor = const Color(0xFFE5E7EB),
    this.textColor = const Color(0xFF9CA3AF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }
}
