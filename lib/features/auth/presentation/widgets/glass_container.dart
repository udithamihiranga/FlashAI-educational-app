import 'package:flutter/material.dart';
import 'package:flashai/core/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double opacity;
  final Color? tintColor;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 20,
    this.opacity = 0.15,
    this.tintColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}