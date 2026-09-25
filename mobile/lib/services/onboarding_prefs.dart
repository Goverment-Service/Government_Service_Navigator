import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device that the user has finished onboarding (slides, terms, sign up / first login),
/// so later launches go straight from the loading animation to the login page.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const _completedKey = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_completedKey) ?? false;
    } catch (_) {
      // Storage unavailable: fall back to showing onboarding rather than blocking startup
      return false;
    }
  }

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
    } catch (_) {
      // Not fatal: onboarding is simply shown again next launch
    }
  }
}
