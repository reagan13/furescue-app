import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

ThemeData buildFuRescueTheme([AppTokens? tokens]) {
  final t = tokens ?? AppTokens.light;
  final nunito = GoogleFonts.nunitoTextTheme(_textTheme(t));
  final dmSans = GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: t.ink);

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: t.jungle,
    onPrimary: t.primaryForeground,
    primaryContainer: t.jungle.withValues(alpha: 0.12),
    onPrimaryContainer: t.jungle,
    secondary: t.paper,
    onSecondary: t.ink,
    secondaryContainer: t.paperDark,
    onSecondaryContainer: t.ink,
    tertiary: t.teal,
    onTertiary: t.primaryForeground,
    error: t.destructive,
    onError: t.primaryForeground,
    surface: t.card,
    onSurface: t.ink,
    onSurfaceVariant: t.mutedForeground,
    outline: t.border,
    surfaceContainerHighest: t.paperDark,
    surfaceTint: Colors.transparent,
  );

  final buttonRadius = BorderRadius.circular(t.radius + 2);
  final inputRadius = BorderRadius.circular(t.radius - 2);
  final cardRadius = BorderRadius.circular(t.radiusCard);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.paper,
    canvasColor: t.paper,
    textTheme: nunito,
    extensions: [t],
    appBarTheme: AppBarTheme(
      backgroundColor: t.paper,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: dmSans.copyWith(fontSize: 20),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.card,
      elevation: 0,
      height: 72,
      indicatorColor: t.jungle.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? t.jungle : t.stamp, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return nunito.labelMedium?.copyWith(
          color: selected ? t.jungle : t.stamp,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: t.jungle,
        foregroundColor: t.primaryForeground,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        textStyle: nunito.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.jungle,
        textStyle: nunito.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: t.card,
        foregroundColor: t.ink,
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        textStyle: nunito.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.paper,
      hintStyle: nunito.bodyMedium?.copyWith(color: t.stamp),
      labelStyle: nunito.labelLarge?.copyWith(color: t.ink),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: t.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: t.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: t.jungle, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: t.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: t.destructive, width: 1.4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.card,
      contentTextStyle: nunito.bodyMedium?.copyWith(color: t.ink),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radius),
        side: BorderSide(color: t.border),
      ),
    ),
    cardTheme: CardThemeData(
      color: t.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: t.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      titleTextStyle: nunito.titleLarge,
      contentTextStyle: nunito.bodyLarge,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.muted,
      selectedColor: t.jungle.withValues(alpha: 0.12),
      disabledColor: t.muted,
      labelStyle: nunito.labelMedium!.copyWith(
        color: t.jungle,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: nunito.labelMedium!.copyWith(color: t.stamp),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      showCheckmark: false,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.jungle,
      foregroundColor: t.primaryForeground,
      elevation: 2,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? t.jungle : t.card;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? t.jungle.withValues(alpha: 0.45)
            : t.muted;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? t.jungle : t.border;
      }),
    ),
    dividerTheme: DividerThemeData(color: t.border, space: 24),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.jungle),
  );
}

TextTheme _textTheme(AppTokens tokens) {
  return TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: tokens.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: tokens.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: tokens.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: tokens.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: tokens.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: tokens.mutedForeground,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: tokens.stamp,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: tokens.ink,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: tokens.stamp,
    ),
  );
}
