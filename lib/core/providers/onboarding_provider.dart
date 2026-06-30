import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Set once in main() before runApp so the initial state is correct.
bool initialOnboardingSeen = false;

class _OnboardingSeenNotifier extends Notifier<bool> {
  @override
  bool build() => initialOnboardingSeen;

  void markSeen() => state = true;
}

final onboardingSeenProvider = NotifierProvider<_OnboardingSeenNotifier, bool>(
  _OnboardingSeenNotifier.new,
);

Future<void> markOnboardingSeen(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_seen', true);
  initialOnboardingSeen = true;
  ref.read(onboardingSeenProvider.notifier).markSeen();
}
