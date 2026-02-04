import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/providers.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'main_scaffold.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to redirect automatically
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        // If we want to react to real-time auth changes (like logout from another device),
        // we can handle it here, or just rely on the build method's stream/state.
        // For now, we'll let the provider logic handle the initial load.
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // 1. If no session, show Login Page
    if (session == null) {
      return const LoginPage();
    }

    // 2. If session exists, fetch profile to check if onboarding is needed
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        // If profile fetch returned null (shouldn't happen for valid user, but handle it)
        if (profile == null) {
          // If we have a user but no profile, maybe they just registered?
          // Or profile fetch failed. We can assume we need onboarding or at least profile setup.
          return const OnboardingPage();
        }

        if (profile.age == null ||
            profile.gender == null ||
            profile.height == null ||
            profile.goal == null) {
          debugPrint('AuthGate: Missing fields -> Redirecting to Onboarding');
          debugPrint(
            'Age: ${profile.age}, Gender: ${profile.gender}, Height: ${profile.height}, Goal: ${profile.goal}',
          );
          return const OnboardingPage();
        }

        // If all good, show Main App
        return const MainScaffold();
      },
      loading:
          () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando perfil...'),
                ],
              ),
            ),
          ),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error al cargar perfil'),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(userProfileProvider);
                    },
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      // Auth state change will trigger rebuild -> LoginPage
                    },
                    child: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
