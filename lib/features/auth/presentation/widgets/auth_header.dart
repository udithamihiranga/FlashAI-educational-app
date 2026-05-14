import 'package:flutter/material.dart';

/// Reusable Auth Header Widget with orange background and icon
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;

  const AuthHeader({
    Key? key,
    this.icon = Icons.layers,
    this.backgroundColor = const Color(0xFFFFA500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 48)),
    );
  }
}
