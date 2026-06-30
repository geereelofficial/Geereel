import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Set once in main() before runApp so the router can read it synchronously.
bool initialOnboardingSeen = false;

final onboardingSeenProvider = Provider<bool>((ref) => initialOnboardingSeen);

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_seen', true);
  initialOnboardingSeen = true;
}
