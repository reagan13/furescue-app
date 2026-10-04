import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CSS `hsl(H S% L%)` from `tokens.css` → [Color].
Color hslToken(double h, double sPercent, double lPercent, [double alpha = 1]) {
  final s = (sPercent / 100).clamp(0.0, 1.0);
  final l = (lPercent / 100).clamp(0.0, 1.0);
  final c = (1 - (2 * l - 1).abs()) * s;
  final hp = (h % 360) / 60;
  final x = c * (1 - ((hp % 2) - 1).abs());
  final double r1;
  final double g1;
  final double b1;
  if (hp < 1) {
    r1 = c;
    g1 = x;
    b1 = 0;
  } else if (hp < 2) {
    r1 = x;
    g1 = c;
    b1 = 0;
  } else if (hp < 3) {
    r1 = 0;
    g1 = c;
    b1 = x;
  } else if (hp < 4) {
    r1 = 0;
    g1 = x;
    b1 = c;
  } else if (hp < 5) {
    r1 = x;
    g1 = 0;
    b1 = c;
  } else {
    r1 = c;
    g1 = 0;
    b1 = x;
  }
  final m = l - c / 2;
  return Color.fromRGBO(
    ((r1 + m) * 255).round(),
    ((g1 + m) * 255).round(),
    ((b1 + m) * 255).round(),
    alpha,
  );
}

/// Port of `:root` in `D:\pepot\furescue\public\assets\css\tokens.css`.
/// Widgets read these fields — not raw hex.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.paper,
    required this.paperDark,
    required this.ink,
    required this.jungle,
    required this.jungle2,
    required this.coral,
    required this.teal,
    required this.stamp,
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.destructive,
    required this.primaryForeground,
    required this.statusPending,
    required this.statusProgress,
    required this.statusSuccess,
    required this.statusDanger,
    required this.chipSuccess,
    required this.chipSuccessFg,
    required this.radius,
    required this.radiusCard,
    required this.radiusXl,
    required this.shadowSm,
    required this.shadowMd,
    required this.systemUi,
  });

  final Color paper;
  final Color paperDark;
  final Color ink;
  final Color jungle;
  final Color jungle2;
  final Color coral;
  final Color teal;
  final Color stamp;
  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color destructive;
  final Color primaryForeground;
  final Color statusPending;
  final Color statusProgress;
  final Color statusSuccess;
  final Color statusDanger;

  /// Web `.rchip--success` green (`hsl(150 70% 32%)`), not `--status-success`.
  final Color chipSuccess;
  final Color chipSuccessFg;
  final double radius;

  /// Web `.rcard` / `.card` (`0.9rem`).
  final double radiusCard;
  final double radiusXl;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final SystemUiOverlayStyle systemUi;

  Color get background => paper;
  Color get foreground => ink;
  Color get primary => jungle;
  Color get ring => jungle;

  static final light = AppTokens(
    paper: hslToken(0, 0, 96),
    paperDark: hslToken(0, 8, 90),
    ink: hslToken(110, 28, 14),
    jungle: hslToken(110, 40, 33),
    jungle2: hslToken(110, 28, 62),
    coral: hslToken(18, 62, 48),
    teal: hslToken(110, 25, 38),
    stamp: hslToken(0, 4, 42),
    card: hslToken(0, 0, 100),
    muted: hslToken(0, 8, 90),
    mutedForeground: hslToken(0, 4, 42),
    border: hslToken(0, 6, 88),
    destructive: hslToken(0, 72, 51),
    primaryForeground: hslToken(0, 0, 100),
    statusPending: hslToken(38, 92, 50),
    statusProgress: hslToken(217, 91, 60),
    statusSuccess: hslToken(110, 40, 33),
    statusDanger: hslToken(4, 77, 55),
    chipSuccess: hslToken(150, 70, 32),
    chipSuccessFg: hslToken(150, 70, 26),
    radius: 8,
    radiusCard: 14.4,
    radiusXl: 20,
    shadowSm: [
      BoxShadow(
        color: hslToken(110, 28, 14, 0.06),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
    shadowMd: [
      BoxShadow(
        color: hslToken(110, 28, 14, 0.18),
        blurRadius: 30,
        spreadRadius: -12,
        offset: const Offset(0, 10),
      ),
    ],
    systemUi: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: hslToken(0, 0, 96),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension FuRescueTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

abstract final class AppSpace {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
