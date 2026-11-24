import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/dua_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/battery_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/reminder_scheduler.dart';

// Infrastructure providers. The ones that need async setup are created in
// main() and injected with ProviderScope overrides.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final duaRepositoryProvider = Provider<DuaRepository>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// Error raised while initializing Firebase (null = OK). Overridden in main().
final firebaseInitErrorProvider = Provider<Object?>((ref) => null);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final batteryServiceProvider = Provider<BatteryService>((ref) => BatteryService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(FirebaseAuth.instance),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(
    notifications: ref.watch(notificationServiceProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    duaRepository: ref.watch(duaRepositoryProvider),
  ),
);
