// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mohammed\'s Dua';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get openSettings => 'Open settings';

  @override
  String get loading => 'Loading…';

  @override
  String get login => 'Log in';

  @override
  String get signup => 'Sign up';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm =>
      'Log out of your account? Scheduled reminders on this device will be cancelled.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to receive your dua reminders';

  @override
  String get createAccount => 'Create account';

  @override
  String get signupSubtitle => 'Create an account to get started';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get forgotPasswordHint =>
      'Enter your account email and we\'ll send you a link to reset your password.';

  @override
  String resetEmailSent(String email) {
    return 'If an account exists for $email, a reset link has been sent. Check your inbox and spam folder.';
  }

  @override
  String get backToLogin => 'Back to login';

  @override
  String get errInvalidEmail => 'That email address is not valid.';

  @override
  String get errUserDisabled => 'This account has been disabled.';

  @override
  String get errWrongCredentials => 'Incorrect email or password.';

  @override
  String get errEmailInUse => 'An account already exists with this email.';

  @override
  String get errWeakPassword =>
      'That password is too weak. Use at least 6 characters.';

  @override
  String get errTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get errOperationNotAllowed =>
      'Email/password sign-in is not enabled for this Firebase project.';

  @override
  String get errUnknown => 'Something went wrong. Please try again.';

  @override
  String get firebaseNotConfiguredTitle => 'Firebase is not configured';

  @override
  String get firebaseNotConfiguredBody =>
      'Run `flutterfire configure` to generate lib/firebase_options.dart, then restart the app. See the README for step-by-step instructions.';

  @override
  String get navHome => 'Home';

  @override
  String get navDuas => 'Duas';

  @override
  String get navSettings => 'Settings';

  @override
  String get duaOfTheMoment => 'Dua of the moment';

  @override
  String get nextReminder => 'Next reminder';

  @override
  String get noUpcoming => 'No reminder scheduled';

  @override
  String get remindersOff => 'Reminders are off';

  @override
  String get currentGap => 'Every';

  @override
  String get remindersEnabled => 'Reminders';

  @override
  String scheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders queued',
      one: '1 reminder queued',
      zero: 'Nothing scheduled',
    );
    return '$_temp0';
  }

  @override
  String get inexactNote =>
      'Times may drift by a few minutes (precise timing is off).';

  @override
  String refillHint(String duration) {
    return 'Open the app at least once every $duration to keep reminders flowing.';
  }

  @override
  String get searchDuas => 'Search duas';

  @override
  String get noDuasFound => 'No duas match your search';

  @override
  String get noFavorites =>
      'No favorites yet. Tap the heart on a dua to add it.';

  @override
  String get all => 'All';

  @override
  String get favorites => 'Favorites';

  @override
  String duaNumber(int number) {
    return 'Dua $number';
  }

  @override
  String get noDuasLoaded => 'No duas available';

  @override
  String get duasLoadError =>
      'Couldn\'t read the duas file. Check assets/data/duas.json is valid JSON.';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get transliteration => 'Transliteration';

  @override
  String get translation => 'Translation';

  @override
  String get reference => 'Reference';

  @override
  String get duaNotFound => 'This dua is no longer available.';

  @override
  String get settings => 'Settings';

  @override
  String get reminders => 'Reminders';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get interval => 'Time between reminders';

  @override
  String get custom => 'Custom';

  @override
  String get customInterval => 'Custom interval';

  @override
  String get minutes => 'Minutes';

  @override
  String get hours => 'Hours';

  @override
  String get enterNumber => 'Number';

  @override
  String invalidNumber(int min, int max) {
    return 'Enter a whole number between $min and $max';
  }

  @override
  String get quietHours => 'Quiet hours';

  @override
  String quietHoursSubtitle(String start, String end) {
    return 'No reminders between $start and $end';
  }

  @override
  String get quietHoursOff => 'Off';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get order => 'Dua order';

  @override
  String get orderSequential => 'Sequential';

  @override
  String get orderRandom => 'Random';

  @override
  String get orderFavorites => 'Favorites only';

  @override
  String get favoritesEmptyWarning =>
      'You have no favorites yet, so all duas will be used.';

  @override
  String get sound => 'Sound';

  @override
  String get soundSubtitle => 'Play a sound with each reminder';

  @override
  String get testNotification => 'Send test notification now';

  @override
  String get testNotificationSent => 'Test notification sent';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get account => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get reliability => 'Delivery & permissions';

  @override
  String get preciseTiming => 'Precise timing';

  @override
  String get preciseTimingOn => 'Allowed — reminders fire on time';

  @override
  String get preciseTimingOff =>
      'Not allowed — Android may delay reminders. Tap to allow.';

  @override
  String get batteryOptimization => 'Battery optimization';

  @override
  String get batteryOptimizationOn =>
      'Restricted — reminders may be delayed. Tap to fix.';

  @override
  String get batteryOptimizationOff => 'Unrestricted';

  @override
  String get batteryDialogTitle => 'Reminders arriving late?';

  @override
  String get batteryDialogBody =>
      'Android\'s battery saver can delay or block scheduled notifications, especially on Xiaomi, Huawei, Oppo, Vivo, OnePlus and Samsung phones.\n\n1. Allow the app to ignore battery optimization.\n2. On some phones also enable \"Autostart\" and set battery usage to \"Unrestricted\" / \"No restrictions\" in App info.';

  @override
  String get allow => 'Allow';

  @override
  String get allowed => 'Allowed';

  @override
  String get notificationsDisabledTitle => 'Notifications are off';

  @override
  String get notificationsDisabledBody =>
      'Mohammed\'s Dua can\'t show reminders until you allow notifications. You can turn them on in the system settings.';

  @override
  String get enableNotifications => 'Allow notifications';

  @override
  String get notificationTitle => 'Dua reminder';

  @override
  String get testNotificationTitle => 'Dua reminder (test)';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';
}
