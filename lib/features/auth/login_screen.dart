import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/auth_error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      // AuthGate switches to Home via authStateChanges.
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.welcomeBack,
      subtitle: l10n.loginSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) AuthErrorBanner(_error!),
              EmailField(
                controller: _email,
                label: l10n.email,
                validator: (v) => Validators.email(l10n, v),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                label: l10n.password,
                validator: (v) => Validators.password(l10n, v),
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              ForgotPasswordScreen(initialEmail: _email.text))),
                  child: Text(l10n.forgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              LoadingButton(label: l10n.login, loading: _loading, onPressed: _submit),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(l10n.noAccount)),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text(l10n.signup),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
