import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:ghost_scale/providers/app_state.dart';
import 'package:ghost_scale/ui/screens/home_screen.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "100% Private",
          body:
              "Your photos never leave this phone. No cloud uploads. No spying.",
          image: const Center(
            child: Text("🛡️", style: TextStyle(fontSize: 100)),
          ),
          decoration: _pageDecoration,
        ),
        PageViewModel(
          title: "Offline AI Power",
          body: "Uses your phone's processor. Works in Airplane Mode.",
          image: const Center(
            child: Text("🚀", style: TextStyle(fontSize: 100)),
          ),
          decoration: _pageDecoration,
        ),
        PageViewModel(
          title: "Unlimited & Free",
          body: "No subscriptions. No credit cards. Just clean pixels.",
          image: const Center(
            child: Text("✨", style: TextStyle(fontSize: 100)),
          ),
          decoration: _pageDecoration,
        ),
      ],
      onDone: () {
        ref.read(appStateProvider).completeOnboarding();
        ref.read(onboardingSeenProvider.notifier).state = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Text("Next"),
      done: const Text(
        "Get Started",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        color: Colors.white24,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      baseBtnStyle: TextButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
      ),
      doneStyle: TextButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
      ),
      skipStyle: TextButton.styleFrom(foregroundColor: Colors.white54),
      nextStyle: TextButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  static const _pageDecoration = PageDecoration(
    titleTextStyle: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    bodyTextStyle: TextStyle(fontSize: 19.0, color: Colors.white70),
    pageColor: Color(0xFF0A0A0A),
    imagePadding: EdgeInsets.zero,
  );
}
