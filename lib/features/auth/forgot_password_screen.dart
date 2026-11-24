import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/auth_error_mapper.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _loading = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
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
    final email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) setState(() => _sentTo = email);
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an account exists (user-not-found): show the
      // same neutral success message.
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        setState(() => _sentTo = email);
      } else {
        setState(() => _error = authErrorMessage(l10n, e));
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AuthScaffold(
      title: l10n.resetPassword,
      subtitle: l10n.forgotPasswordHint,
      showBack: true,
      child: _sentTo != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.mark_email_read_outlined, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.resetEmailSent(_sentTo!),
                          style: TextStyle(color: scheme.onPrimaryContainer)),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.backToLogin),
                ),
              ],
            )
          : Form(
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
                  const SizedBox(height: 24),
                  LoadingButton(
                      label: l10n.sendResetLink, loading: _loading, onPressed: _submit),
                ],
              ),
            ),
    );
  }
}
