import 'package:flutter/material.dart';

/// Reusable Auth Link Widget for navigation between pages
class AuthLink extends StatelessWidget {
  final String mainText;
  final String linkText;
  final VoidCallback onTap;
  final Color linkColor;
  final Color textColor;

  const AuthLink({
    Key? key,
    required this.mainText,
    required this.linkText,
    required this.onTap,
    this.linkColor = const Color(0xFFFFA500),
    this.textColor = const Color(0xFF6B7280),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: RichText(
          text: TextSpan(
            text: mainText,
            style: TextStyle(color: textColor, fontSize: 14),
            children: [
              TextSpan(
                text: linkText,
                style: TextStyle(
                  color: linkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
