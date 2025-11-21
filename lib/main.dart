import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghost_scale/ui/theme/app_theme.dart';
import 'package:ghost_scale/ui/screens/onboarding_screen.dart';
import 'package:ghost_scale/ui/screens/home_screen.dart';
import 'package:ghost_scale/providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GhostScaleApp(),
    ),
  );
}

class GhostScaleApp extends ConsumerWidget {
  const GhostScaleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seenOnboarding = ref.watch(onboardingSeenProvider);

    return MaterialApp(
      title: 'GhostScale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: seenOnboarding ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
