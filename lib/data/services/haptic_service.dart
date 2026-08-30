import 'package:flutter/services.dart';

import 'hive_service.dart';

/// Thin wrapper over [HapticFeedback] that respects the user's Vibration
/// setting (`setting_vibration` in Hive — OFF by default, toggled in
/// Profile → Settings). Call sites can safely call these everywhere; they
/// no-op when vibration is disabled.
class Haptics {
  Haptics._();

  /// Setting key shared with UserProvider (Hive meta box).
  static const String settingKey = 'setting_vibration';

  static bool get enabled => HiveService.getMeta<bool>(settingKey) ?? false;

  /// Soft tick for taps, tab switches and countdown ticks.
  static void tap() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Light impact for small positives (correct answer, lifeline).
  static void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact for notable events (reward, unlock, purchase).
  static void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Strong impact for big moments (win, perfect score).
  static void heavy() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Error buzz for wrong answers and denied actions.
  static void error() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }
}
