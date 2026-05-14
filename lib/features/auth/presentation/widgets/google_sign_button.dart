import 'package:flutter/material.dart';

/// Reusable Google Sign In/Up Button Widget
class GoogleSignButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const GoogleSignButton({
    Key? key,
    required this.onPressed,
    this.label = 'Continue with Google',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: _buildGoogleIcon(),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Builds a simple Google icon (can be replaced with asset)
  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
