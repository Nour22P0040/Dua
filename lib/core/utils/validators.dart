import '../../l10n/app_localizations.dart';

class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(AppLocalizations l10n, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.emailRequired;
    if (!_emailRegex.hasMatch(v)) return l10n.emailInvalid;
    return null;
  }

  static String? password(AppLocalizations l10n, String? value) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.passwordRequired;
    if (v.length < 6) return l10n.passwordTooShort;
    return null;
  }
}
