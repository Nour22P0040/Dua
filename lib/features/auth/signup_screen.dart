import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/auth_error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
          .signUp(email: _email.text, password: _password.text);
      // Signing up also signs in. The AuthGate (root route) now shows Home,
      // so drop this pushed route to reveal it.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
      title: l10n.createAccount,
      subtitle: l10n.signupSubtitle,
      showBack: true,
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
                isNewPassword: true,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.password(l10n, v),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                label: l10n.confirmPassword,
                isNewPassword: true,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _password.text ? l10n.passwordsDontMatch : null,
              ),
              const SizedBox(height: 24),
              LoadingButton(label: l10n.signup, loading: _loading, onPressed: _submit),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(l10n.haveAccount)),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.login),
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
