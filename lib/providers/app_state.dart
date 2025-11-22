import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enums for Settings
enum UpscaleModel { standard, pro }

enum UpscaleResolution { fast2k, ultra4k }

// Providers for Settings
final upscaleModelProvider = StateProvider<UpscaleModel>(
  (ref) => UpscaleModel.standard,
);
final upscaleResolutionProvider = StateProvider<UpscaleResolution>(
  (ref) => UpscaleResolution.fast2k,
);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final onboardingSeenProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('onboarding_seen') ?? false;
});

final successfulUpscalesProvider = StateNotifierProvider<AppStateNotifier, int>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppStateNotifier(prefs);
  },
);

class AppStateNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;

  AppStateNotifier(this._prefs) : super(_prefs.getInt('upscale_count') ?? 0);

  void incrementUpscaleCount() {
    state++;
    _prefs.setInt('upscale_count', state);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('onboarding_seen', true);
  }
}

final appStateProvider = Provider(
  (ref) => ref.watch(successfulUpscalesProvider.notifier),
);
