// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دعاء محمد';

  @override
  String get ok => 'حسناً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get save => 'حفظ';

  @override
  String get close => 'إغلاق';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm =>
      'هل تريد تسجيل الخروج؟ سيتم إلغاء التذكيرات المجدولة على هذا الجهاز.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get emailRequired => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get emailInvalid => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get passwordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordTooShort => 'يجب ألا تقل كلمة المرور عن 6 أحرف';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لتصلك تذكيرات الدعاء';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get signupSubtitle => 'أنشئ حساباً للبدء';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get forgotPasswordHint =>
      'أدخل بريد حسابك وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String resetEmailSent(String email) {
    return 'إذا كان هناك حساب مرتبط بـ $email فقد أُرسل رابط إعادة التعيين. تحقق من البريد الوارد ومجلد الرسائل غير المرغوب فيها.';
  }

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get errInvalidEmail => 'البريد الإلكتروني غير صالح.';

  @override
  String get errUserDisabled => 'تم تعطيل هذا الحساب.';

  @override
  String get errWrongCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errEmailInUse => 'يوجد حساب مسجّل بهذا البريد بالفعل.';

  @override
  String get errWeakPassword => 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.';

  @override
  String get errTooManyRequests =>
      'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';

  @override
  String get errNetwork =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.';

  @override
  String get errOperationNotAllowed =>
      'تسجيل الدخول بالبريد وكلمة المرور غير مفعّل في مشروع Firebase.';

  @override
  String get errUnknown => 'حدث خطأ ما. حاول مجدداً.';

  @override
  String get firebaseNotConfiguredTitle => 'لم يتم إعداد Firebase';

  @override
  String get firebaseNotConfiguredBody =>
      'شغّل الأمر flutterfire configure لإنشاء الملف lib/firebase_options.dart ثم أعد تشغيل التطبيق. راجع ملف README للخطوات.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navDuas => 'الأدعية';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get duaOfTheMoment => 'دعاء اللحظة';

  @override
  String get nextReminder => 'التذكير القادم';

  @override
  String get noUpcoming => 'لا يوجد تذكير مجدول';

  @override
  String get remindersOff => 'التذكيرات متوقفة';

  @override
  String get currentGap => 'كل';

  @override
  String get remindersEnabled => 'التذكيرات';

  @override
  String scheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير في الانتظار',
      many: '$count تذكيراً في الانتظار',
      few: '$count تذكيرات في الانتظار',
      two: 'تذكيران في الانتظار',
      one: 'تذكير واحد في الانتظار',
      zero: 'لا شيء مجدول',
    );
    return '$_temp0';
  }

  @override
  String get inexactNote =>
      'قد تتأخر المواعيد بضع دقائق (التوقيت الدقيق غير مفعّل).';

  @override
  String refillHint(String duration) {
    return 'افتح التطبيق مرة واحدة على الأقل كل $duration لتستمر التذكيرات.';
  }

  @override
  String get searchDuas => 'ابحث في الأدعية';

  @override
  String get noDuasFound => 'لا توجد أدعية مطابقة';

  @override
  String get noFavorites => 'لا توجد مفضلة بعد. اضغط على القلب لإضافة دعاء.';

  @override
  String get all => 'الكل';

  @override
  String get favorites => 'المفضلة';

  @override
  String duaNumber(int number) {
    return 'دعاء $number';
  }

  @override
  String get noDuasLoaded => 'لا توجد أدعية';

  @override
  String get duasLoadError =>
      'تعذّرت قراءة ملف الأدعية. تأكد أن assets/data/duas.json بصيغة JSON صحيحة.';

  @override
  String get copy => 'نسخ';

  @override
  String get share => 'مشاركة';

  @override
  String get copied => 'تم النسخ';

  @override
  String get addFavorite => 'إضافة إلى المفضلة';

  @override
  String get removeFavorite => 'إزالة من المفضلة';

  @override
  String get transliteration => 'النطق';

  @override
  String get translation => 'الترجمة';

  @override
  String get reference => 'المصدر';

  @override
  String get duaNotFound => 'هذا الدعاء لم يعد متوفراً.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get reminders => 'التذكيرات';

  @override
  String get enableReminders => 'تفعيل التذكيرات';

  @override
  String get interval => 'المدة بين التذكيرات';

  @override
  String get custom => 'مخصص';

  @override
  String get customInterval => 'مدة مخصصة';

  @override
  String get minutes => 'دقائق';

  @override
  String get hours => 'ساعات';

  @override
  String get enterNumber => 'العدد';

  @override
  String invalidNumber(int min, int max) {
    return 'أدخل عدداً صحيحاً بين $min و $max';
  }

  @override
  String get quietHours => 'ساعات الهدوء';

  @override
  String quietHoursSubtitle(String start, String end) {
    return 'لا تذكيرات من $start إلى $end';
  }

  @override
  String get quietHoursOff => 'متوقفة';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get order => 'ترتيب الأدعية';

  @override
  String get orderSequential => 'بالترتيب';

  @override
  String get orderRandom => 'عشوائي';

  @override
  String get orderFavorites => 'المفضلة فقط';

  @override
  String get favoritesEmptyWarning =>
      'لا توجد مفضلة بعد، لذلك ستُستخدم كل الأدعية.';

  @override
  String get sound => 'الصوت';

  @override
  String get soundSubtitle => 'تشغيل صوت مع كل تذكير';

  @override
  String get testNotification => 'إرسال إشعار تجريبي الآن';

  @override
  String get testNotificationSent => 'تم إرسال الإشعار التجريبي';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'حسب النظام';

  @override
  String get account => 'الحساب';

  @override
  String signedInAs(String email) {
    return 'مسجّل الدخول باسم $email';
  }

  @override
  String get reliability => 'الإشعارات والأذونات';

  @override
  String get preciseTiming => 'التوقيت الدقيق';

  @override
  String get preciseTimingOn => 'مسموح — تصل التذكيرات في موعدها';

  @override
  String get preciseTimingOff =>
      'غير مسموح — قد يؤخر أندرويد التذكيرات. اضغط للسماح.';

  @override
  String get batteryOptimization => 'تحسين البطارية';

  @override
  String get batteryOptimizationOn =>
      'مقيّد — قد تتأخر التذكيرات. اضغط للإصلاح.';

  @override
  String get batteryOptimizationOff => 'غير مقيّد';

  @override
  String get batteryDialogTitle => 'هل تصل التذكيرات متأخرة؟';

  @override
  String get batteryDialogBody =>
      'قد يؤخر موفّر البطارية في أندرويد الإشعارات المجدولة أو يمنعها، خصوصاً على هواتف شاومي وهواوي وأوبو وفيفو ووان بلس وسامسونج.\n\n1. اسمح للتطبيق بتجاهل تحسين البطارية.\n2. في بعض الهواتف فعّل أيضاً \"التشغيل التلقائي\" واجعل استخدام البطارية \"بلا قيود\" من معلومات التطبيق.';

  @override
  String get allow => 'سماح';

  @override
  String get allowed => 'مسموح';

  @override
  String get notificationsDisabledTitle => 'الإشعارات متوقفة';

  @override
  String get notificationsDisabledBody =>
      'لا يمكن عرض التذكيرات حتى تسمح بالإشعارات. يمكنك تفعيلها من إعدادات النظام.';

  @override
  String get enableNotifications => 'السماح بالإشعارات';

  @override
  String get notificationTitle => 'تذكير بالدعاء';

  @override
  String get testNotificationTitle => 'تذكير بالدعاء (تجربة)';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غداً';
}
