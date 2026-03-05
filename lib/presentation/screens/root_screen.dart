import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/theme.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// Provider to check if onboarding is completed
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final supabase = Supabase.instance.client;
  
  // Sign in anonymously if not authenticated
  if (supabase.auth.currentUser == null) {
    await supabase.auth.signInAnonymously();
  }
  
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return false;
  
  // Check profile for onboarding_completed
  final response = await supabase
      .from('profiles')
      .select('onboarding_completed')
      .eq('id', userId)
      .maybeSingle();
  
  if (response == null) {
    // No profile yet — create one and show onboarding
    await supabase.from('profiles').insert({
      'id': userId,
      'onboarding_completed': false,
    });
    return false;
  }
  
  return response['onboarding_completed'] == true;
});

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingStatus = ref.watch(onboardingStatusProvider);

    return onboardingStatus.when(
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(error: error.toString()),
      data: (isCompleted) {
        if (isCompleted) {
          return const HomeScreen();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                '문제가 발생했어요',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
