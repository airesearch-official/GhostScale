import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final onboardingSeenProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('seenOnboarding') ?? false;
});

final successfulUpscalesProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('successful_upscales') ?? 0;
});

class AppStateNotifier extends StateNotifier<void> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(null);

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('seenOnboarding', true);
    ref.read(onboardingSeenProvider.notifier).state = true;
  }

  Future<void> incrementUpscaleCount() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final current = ref.read(successfulUpscalesProvider);
    await prefs.setInt('successful_upscales', current + 1);
    ref.read(successfulUpscalesProvider.notifier).state = current + 1;
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, void>((ref) {
  return AppStateNotifier(ref);
});
