import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';

/// Maps a [FirebaseAuthException] code (or any error) to a friendly,
/// localized message. Never exposes raw Firebase messages to users.
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! FirebaseAuthException) return l10n.errUnknown;
  switch (error.code) {
    case 'invalid-email':
    case 'missing-email':
      return l10n.errInvalidEmail;
    case 'user-disabled':
      return l10n.errUserDisabled;
    // Newer Firebase projects (email enumeration protection) return
    // `invalid-credential` instead of user-not-found / wrong-password.
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return l10n.errWrongCredentials;
    case 'email-already-in-use':
      return l10n.errEmailInUse;
    case 'weak-password':
      return l10n.errWeakPassword;
    case 'too-many-requests':
      return l10n.errTooManyRequests;
    case 'network-request-failed':
      return l10n.errNetwork;
    case 'operation-not-allowed':
      return l10n.errOperationNotAllowed;
    default:
      return l10n.errUnknown;
  }
}
