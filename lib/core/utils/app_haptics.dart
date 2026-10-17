import 'package:flutter/services.dart';

/// Centralized institutional haptic feedback manager.
/// Provides refined, purposeful tactile feedback matching modern iOS Taptic Engine
/// and Android tactile standards without overwhelming the user experience.
class AppHaptics {
  const AppHaptics._();

  /// Subtle tactile tick for selection controls, tab switches, and segmented selectors.
  /// (e.g. timeframe pills, tab bar taps, chip selections)
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Soft mechanical feedback for secondary interactions.
  /// (e.g. password visibility toggle, remember-me checkmark, quick-fill cards)
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Crisp, defined feedback for primary actions.
  /// (e.g. "Sign In to Terminal" button tap, "Place Order" tap)
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Assertive feedback for high-importance or destructive confirmations.
  /// (e.g. "Cancel All Orders", "Reset Account", critical threshold crossings)
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Distinctive dual-pulse feedback indicating a successful operation or state transition.
  /// (e.g. successful login, order filled)
  static Future<void> success() async {
    try {
      await HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Strong double-pulse vibration for form validation failures or auth errors.
  /// (e.g. invalid credentials, empty required fields, order rejected)
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Moderate cautionary pulse for threshold crossing or margin limits.
  static Future<void> warning() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Timed, resonant flutter haptic for price alert creation and trigger events.
  /// Produces a distinctive, shaky bell vibration with a decaying micro-pulse sequence
  /// (medium -> light -> light -> selection -> selection) that feels pleasingly mechanical
  /// without being unpleasantly harsh or heavy.
  static Future<void> alertChime() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 45));
      await HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.selectionClick();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
