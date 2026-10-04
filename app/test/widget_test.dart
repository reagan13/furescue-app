import 'package:flutter_test/flutter_test.dart';

import 'package:furescue_app/format/display.dart';
import 'package:furescue_app/theme/tokens.dart';
import 'package:furescue_app/widgets/status_chip.dart';

void main() {
  test('jungle is the study green, not a default Material purple', () {
    final jungle = AppTokens.light.jungle;
    expect(jungle.g, greaterThan(jungle.r));
    expect(jungle.g, greaterThan(jungle.b));
  });

  test('paper is a light page background', () {
    expect(AppTokens.light.paper.computeLuminance(), greaterThan(0.85));
  });

  test('shortId takes the first four hex chars', () {
    expect(shortId('abcd-ef12-3456'), '#ABCD');
    expect(shortId(''), '—');
  });

  test('activity labels stay human-readable', () {
    expect(activityActionLabel('proof_added'), 'Proof added');
    expect(activityActionLabel('status_changed'), 'Status changed');
  });

  test('status chips follow web rchip tones', () {
    expect(statusChipTone('pending'), StatusChipTone.brand);
    expect(statusChipTone('in_progress'), StatusChipTone.brand);
    expect(statusChipTone('assigned'), StatusChipTone.sky);
    expect(statusChipTone('completed'), StatusChipTone.sky);
    expect(statusChipTone('resolved'), StatusChipTone.success);
    expect(statusChipTone('available'), StatusChipTone.success);
    expect(statusChipTone('adopted'), StatusChipTone.muted);
    expect(statusChipTone('rejected'), StatusChipTone.alert);
  });

  test('cards use the web 0.9rem radius, not radius-xl', () {
    expect(AppTokens.light.radiusCard, 14.4);
    expect(AppTokens.light.radiusXl, 20);
  });
}
