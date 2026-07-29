import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized ThemeData per DESIGN.md section 6.
///
/// Design intent (DESIGN.md 1 & 2.1):
/// - Material 3 as the foundation, customized — not the stock look.
/// - A distinct **tertiary** color is used specifically for AI-generated
///   surfaces (summary cards, assistant bubble) so users can tell AI output
///   from human-entered data at a glance. Don't reuse tertiary for anything
///   else, or that signal is lost.
class AppTheme {
  AppTheme._();

  // Brand seed — swap for the real brand color once defined.
  static const _seed = Color(0xFF4F5DFF);

  // Distinct hue for AI content, deliberately not derived from the seed so
  // it reads as a separate signal rather than a shade of the brand color.
  static const _aiAccent = Color(0xFF00BFA6);

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    ).copyWith(
      tertiary: _aiAccent,
      tertiaryContainer: brightness == Brightness.light
          ? _aiAccent.withValues(alpha: 0.12)
          : _aiAccent.withValues(alpha: 0.22),
    );

    final textTheme = GoogleFonts.interTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: scheme.surfaceContainerLow,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }

  /// Use for anything that renders AI-generated content (summaries,
  /// extracted tasks, assistant replies) so it's visually distinct —
  /// DESIGN.md 2.1 and 3.6/3.9.
  static Color aiAccent(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
}
