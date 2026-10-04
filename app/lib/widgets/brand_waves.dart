import 'package:flutter/material.dart';
import 'package:wave/wave.dart';

import '../theme/tokens.dart';

/// Jungle-tinted [WaveWidget] from the `wave` package.
/// Fills its parent; give it a bounded size (fixed height or [Positioned.fill]).
class BrandWaves extends StatelessWidget {
  const BrandWaves({super.key, this.amplitude = 16, this.frequency = 1.35});

  final double amplitude;
  final double frequency;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return WaveWidget(
      config: CustomConfig(
        colors: [
          tokens.jungle2.withValues(alpha: 0.55),
          tokens.teal.withValues(alpha: 0.40),
          tokens.jungle.withValues(alpha: 0.88),
          tokens.paper,
        ],
        durations: const [14000, 11000, 9000, 7000],
        heightPercentages: const [0.42, 0.48, 0.55, 0.62],
      ),
      backgroundColor: tokens.jungle,
      size: const Size(double.infinity, double.infinity),
      waveAmplitude: amplitude,
      waveFrequency: frequency,
    );
  }
}
