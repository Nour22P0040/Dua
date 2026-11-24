import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/message_view.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import 'auth_providers.dart';
import 'login_screen.dart';

/// Root widget: Splash while auth state loads → Login (signed out) or Home.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Firebase failed to initialize (most often: `flutterfire configure`
    // hasn't been run yet). Explain instead of crashing.
    if (ref.watch(firebaseInitErrorProvider) != null) {
      return Scaffold(
        body: SafeArea(
          child: MessageView(
            icon: Icons.cloud_off_rounded,
            title: l10n.firebaseNotConfiguredTitle,
            message: l10n.firebaseNotConfiguredBody,
          ),
        ),
      );
    }

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const SplashScreen(),
      error: (e, _) => Scaffold(
        body: MessageView(
          icon: Icons.error_outline,
          title: l10n.errUnknown,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(authStateProvider),
        ),
      ),
      data: (user) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: user == null
            ? const LoginScreen(key: ValueKey('login'))
            : HomeShell(key: ValueKey('home-${user.uid}')),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nights_stay_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).appTitle,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
