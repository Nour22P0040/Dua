# Dua Reminder

A Flutter app (Android and iOS) that sends a local notification with a different dua at a time gap you choose. You sign in with Firebase email and password.

- Gaps: 15 min, 30 min, 1 h, 2 h, 3 h, 6 h, 12 h or 24 h, or a custom number of minutes or hours. Debug builds also show a 1-minute preset.
- Quiet hours, three orders (sequential, random, favorites only), a sound on/off switch and a test-notification button.
- Tapping a notification opens that dua's detail screen. This works whether the app was closed or running in the background.
- Duas list with Arabic-aware search and favorites, plus a detail screen with Copy and Share buttons.
- Light and dark themes. The interface is in English and Arabic (RTL), and Arabic dua text uses the Amiri font.

## Project structure

```
lib/
  main.dart                    bootstrap: Firebase, prefs, duas, notifications
  app.dart                     MaterialApp (themes, locales)
  firebase_options.dart        PLACEHOLDER – replaced by `flutterfire configure`
  core/                        providers, theme, utils (validators, auth errors, formatters), widgets
  data/
    models/                    Dua (tolerant parser), ReminderSettings, ScheduledReminder
    repositories/              DuaRepository, SettingsRepository, AuthRepository
    services/                  NotificationService, ReminderScheduler (rolling batch), BatteryService
  features/
    auth/                      AuthGate + splash, Login, Sign up, Forgot password
    home/                      HomeShell (tabs, lifecycle, tap handling), Home, ScheduleController
    duas/                      list, detail, favorites
    settings/                  settings screen, controllers, battery dialog, custom interval dialog
  l10n/                        app_en.arb, app_ar.arb (+ generated localizations)
assets/data/duas.json
```

## 1. Firebase setup

1. Go to https://console.firebase.google.com and create a project.
2. Open **Build → Authentication → Get started → Sign-in method** and enable **Email/Password**.
3. Install the CLIs:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```
4. Pick your app ID. This project uses `com.example.dua`. To use your own ID, change `applicationId` and `namespace` in `android/app/build.gradle.kts` and `PRODUCT_BUNDLE_IDENTIFIER` in Xcode. If you change `namespace`, also move `MainActivity.kt` to the matching package.
5. From the project root, run:
   ```bash
   flutterfire configure --platforms=android,ios
   ```
   Select your project. This command:
   - overwrites `lib/firebase_options.dart` (the file in the repo is only a placeholder);
   - adds `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`;
   - may add the Google Services Gradle plugin. Keep it if it does.
6. Run the app. If you skip step 5, the app does not crash. It shows a "Firebase is not configured" screen instead.

Password reset emails come from Firebase. You can change the email template under **Authentication → Templates**.

## 2. Running

```bash
flutter pub get
flutter gen-l10n          # also runs automatically on build
flutter run
```

Requirements: Flutter 3.44+ / Dart 3.12+.

- **Android:** the project needs compileSdk 37, AGP 9.1.1 and Gradle 9.3.1. Core library desugaring is enabled because `flutter_local_notifications` requires it.
- **iOS:** the deployment target is iOS 15, which the Firebase SDK requires. Run `cd ios && pod install` if you use CocoaPods, then open `ios/Runner.xcworkspace` and set your signing team.

## 3. Dua data

Your duas live in `assets/data/duas.json`, which is registered in `pubspec.yaml`. The parser (`Dua.tryParse` / `DuaRepository.parse`) accepts several shapes:

```jsonc
{ "duas": ["…", "…"] }                                   // current file
[ "…", "…" ]
[ { "id": 1, "title": "…", "arabic": "…", "transliteration": "…", "translation": "…", "reference": "…" } ]
```

- Field aliases such as `text`, `dua`, `english` and `source` are also recognized. To support a new field name, add it to the alias lists in `lib/data/models/dua.dart`.
- Entries that are plain strings get IDs from their position (1, 2, 3…). Keep the order stable, or new items will take over existing IDs and favorites will point at different duas.
- Bad entries are skipped. If the whole file is invalid JSON, the app shows a message instead of crashing.

## 4. How scheduling works

The scheduling logic is in `lib/data/services/reminder_scheduler.dart`, which is heavily commented.

- `periodicallyShow` is **not** used. It only supports fixed intervals and always repeats the same content.
- Instead, the app schedules a **rolling batch of 48 one-shot notifications** with `zonedSchedule`, each carrying its own dua.
  - The times are spaced by your chosen gap.
  - Any time that falls in quiet hours moves to the end of the quiet window, and the cadence continues from there.
  - 48 stays under iOS's limit of 64 pending notifications.
- The batch is saved as a "plan". On each refill, entries whose time has passed count as delivered. This moves the rotation forward (the sequential position is saved in shared_preferences) and sets the "dua of the moment" on Home.
- The batch is refilled:
  - when the app opens or comes back from the background;
  - when you change any setting or the language, or change favorites while in favorites-only mode;
  - after a reboot. Android's `ScheduledNotificationBootReceiver` restores the pending batch, and the next app open tops it up.
- Timing changes restart the cadence from now. Order or sound changes keep the current rhythm.
- **Android timing:**
  - Without the exact-alarm permission, the app uses `inexactAllowWhileIdle`.
  - Once you grant **Settings → Precise timing** ("Alarms & reminders"), it uses `exactAllowWhileIdle`.
  - Sound off uses a second, silent channel (`dua_reminders_silent`) because Android channels can't change sound after they're created.
- **Logout** cancels all pending reminders on the device.

## 5. Testing notifications quickly

1. Run a debug build (`flutter run`). In **Settings → Time between reminders**, choose the **1 minute** preset, which only appears in debug. In any build you can also use **Custom → 1 Minutes**.
2. Tap **Send test notification now** to get one immediately.
3. Put the app in the background or lock the phone. A new dua should arrive every minute.
4. Tap a notification. It should open that dua's detail screen, both when the app is killed (cold start) and when it's in the background.
5. To check what Android has scheduled, run `adb shell dumpsys alarm | grep -A3 com.example.dua`.
6. To test the reboot path, run `adb reboot`. Wait for the next reminder without opening the app.

With inexact alarms, Android may group 1-minute reminders together. Grant **Precise timing** for accurate tests.

## 6. Known platform limitations

- **iOS 64-notification limit:** iOS keeps at most 64 pending local notifications per app, so the app queues 48. The queue lasts 48 × your gap:
  - 15 min → 12 hours
  - 1 h → 2 days
  - 24 h → 48 days

  If the app isn't opened before the queue runs out, reminders stop until the next launch. Home shows a hint when the queue covers less than 2 days. iOS also has no reliable way to run code on a timer in the background, which is why this design is used.
- **Android OEM battery killers:** Xiaomi/MIUI/HyperOS, Huawei/EMUI, Oppo/ColorOS, Vivo, OnePlus and Samsung (Deep sleeping apps) can delay or drop scheduled alarms, or stop the boot receiver from running. If reminders arrive late:
  - In the app, use **Settings → Battery optimization**, which opens the system dialog.
  - Enable **Autostart** (Xiaomi, Huawei, Oppo, Vivo).
  - Set battery usage to **Unrestricted** / **No restrictions**, and remove the app from Samsung's "Sleeping apps".
  - See https://dontkillmyapp.com for device-specific steps.
- **Android 12+ exact alarms:** `SCHEDULE_EXACT_ALARM` must be granted by the user, and Android 14+ denies it by default. Without it, reminders can drift by several minutes in Doze.
- **Android 13+:** the user must grant `POST_NOTIFICATIONS`. If they deny it permanently, the app shows a banner with an **Open settings** button.
- **Google Play policy:** `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` is a restricted permission. If your Play listing is rejected because of it, remove it from `AndroidManifest.xml`. The app then opens the app-settings screen instead.
- **Force-stopping the app** (from Android settings) cancels all its alarms until it is opened again. This is OS behavior.
- **Time zone and DST:** times are stored as absolute instants and quiet hours use local wall-clock time. If the time zone changes, the next app open recalculates.

## 7. Bundling the Arabic font (optional, for offline use)

`google_fonts` downloads Amiri the first time and then caches it. To ship the font inside the app instead:

1. Download `Amiri-Regular.ttf` from https://fonts.google.com/specimen/Amiri.
2. Put it in `assets/google_fonts/`.
3. Add `- assets/google_fonts/` to `assets:` in `pubspec.yaml`. `google_fonts` then loads it locally.
4. Optionally, set `GoogleFonts.config.allowRuntimeFetching = false` in `main()`.

## 8. Localization

Strings are in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`. Run `flutter gen-l10n` after editing them. The language follows the device by default, and you can override it in **Settings → Language**.

## 9. Tests

```bash
flutter test
```

The tests cover the JSON parser (string, object and malformed input), quiet-hours shifting (including windows that wrap past midnight) and Arabic search normalization.
