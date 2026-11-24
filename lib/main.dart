import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'data/repositories/dua_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log, never crash, on uncaught errors.
  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  // 1. Firebase. A failure (e.g. firebase_options.dart not generated yet) is
  //    surfaced on screen by AuthGate instead of crashing.
  Object? firebaseError;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    firebaseError = e;
    debugPrint('Firebase init failed: $e');
  }

  // 2. Local storage + dua data (loaded once; malformed JSON → empty list + message).
  final prefs = await SharedPreferences.getInstance();
  final duas = await DuaRepository.load();

  // 3. Notifications: timezone, channels, and cold-start tap payload.
  final notifications = NotificationService();
  await notifications.init(preferredLocale: SettingsRepository(prefs).loadLocale());

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        duaRepositoryProvider.overrideWithValue(duas),
        notificationServiceProvider.overrideWithValue(notifications),
        firebaseInitErrorProvider.overrideWithValue(firebaseError),
      ],
      child: const DuaReminderApp(),
    ),
  );
}
