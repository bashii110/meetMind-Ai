import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// A subtle glassmorphism treatment (DESIGN.md's "glassmorphism accents"
/// polish item) — translucent, blurred background with a soft tinted
/// border. Reserved for AI-generated / insight surfaces (the executive
/// summary card, the meeting score badge, productivity tips) so it reads
/// as an accent, not the app's default card style — `AppTheme`'s
/// existing tertiary-color convention already marks AI content this way;
/// this is the same signal, expressed as a texture instead of just a
/// color.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(Spacing.cardRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.tertiary.withValues(alpha: 0.16),
                scheme.tertiary.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: scheme.tertiary.withValues(alpha: 0.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}
