import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/reminder_settings.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_providers.dart';
import '../duas/favorites_controller.dart';
import '../home/permission_banner.dart';
import '../home/schedule_controller.dart';
import 'battery_dialog.dart';
import 'settings_controller.dart';
import 'widgets/custom_interval_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Preset gaps in minutes. A 1-minute preset is added in debug builds
  /// to test notifications quickly.
  static const presets = [15, 30, 60, 120, 180, 360, 720, 1440];
  static List<int> get visiblePresets => kDebugMode ? [1, ...presets] : presets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(reminderSettingsProvider);
    final controller = ref.read(reminderSettingsProvider.notifier);
    final favorites = ref.watch(favoritesProvider);
    final user = ref.watch(authStateProvider).value;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final notificationsAllowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final exactAllowed = ref.watch(exactAlarmAllowedProvider).value ?? true;
    final batteryRestricted = ref.watch(batteryRestrictedProvider).value ?? false;
    final isCustom = !visiblePresets.contains(s.intervalMinutes);

    void update(ReminderSettings next) => controller.update(next);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ------------------------------------------------------- reminders
          _Header(l10n.reminders),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.enableReminders),
            value: s.enabled,
            onChanged: (v) => update(s.copyWith(enabled: v)),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.interval),
            subtitle: Text(formatInterval(l10n, s.intervalMinutes)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in visiblePresets)
                  ChoiceChip(
                    label: Text(formatInterval(l10n, m)),
                    selected: s.intervalMinutes == m,
                    onSelected: s.enabled
                        ? (_) => update(s.copyWith(intervalMinutes: m))
                        : null,
                  ),
                ChoiceChip(
                  avatar: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(isCustom
                      ? '${l10n.custom}: ${formatInterval(l10n, s.intervalMinutes)}'
                      : l10n.custom),
                  selected: isCustom,
                  onSelected: s.enabled
                      ? (_) async {
                          final minutes = await showCustomIntervalDialog(context,
                              initialMinutes: s.intervalMinutes);
                          if (minutes != null) {
                            update(ref
                                .read(reminderSettingsProvider)
                                .copyWith(intervalMinutes: minutes));
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bedtime_outlined),
            title: Text(l10n.quietHours),
            subtitle: Text(s.quietHoursEnabled
                ? l10n.quietHoursSubtitle(formatMinutesOfDay(context, s.quietStartMinutes),
                    formatMinutesOfDay(context, s.quietEndMinutes))
                : l10n.quietHoursOff),
            value: s.quietHoursEnabled,
            onChanged: s.enabled ? (v) => update(s.copyWith(quietHoursEnabled: v)) : null,
          ),
          if (s.quietHoursEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
              child: Row(children: [
                Expanded(
                  child: _TimeButton(
                    label: l10n.from,
                    minutes: s.quietStartMinutes,
                    onPicked: (m) => update(s.copyWith(quietStartMinutes: m)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: l10n.to,
                    minutes: s.quietEndMinutes,
                    onPicked: (m) => update(s.copyWith(quietEndMinutes: m)),
                  ),
                ),
              ]),
            ),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: Text(l10n.order),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<DuaOrder>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: DuaOrder.sequential, label: Text(l10n.orderSequential)),
                ButtonSegment(value: DuaOrder.random, label: Text(l10n.orderRandom)),
                ButtonSegment(value: DuaOrder.favorites, label: Text(l10n.orderFavorites)),
              ],
              selected: {s.order},
              onSelectionChanged: (v) => update(s.copyWith(order: v.first)),
            ),
          ),
          if (s.order == DuaOrder.favorites && favorites.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.favoritesEmptyWarning,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          SwitchListTile(
            secondary: Icon(s.soundEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined),
            title: Text(l10n.sound),
            subtitle: Text(l10n.soundSubtitle),
            value: s.soundEnabled,
            onChanged: (v) => update(s.copyWith(soundEnabled: v)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send_outlined),
              label: Text(l10n.testNotification),
              onPressed: () => _sendTest(context, ref),
            ),
          ),

          // ------------------------------------------------------- reliability
          _Header(l10n.reliability),
          ListTile(
            leading: Icon(notificationsAllowed
                ? Icons.notifications_outlined
                : Icons.notifications_off_outlined),
            title: Text(l10n.enableNotifications),
            subtitle: Text(notificationsAllowed
                ? l10n.allowed
                : l10n.notificationsDisabledTitle),
            trailing: notificationsAllowed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
            onTap: notificationsAllowed
                ? null
                : () => requestNotificationsOrOpenSettings(ref),
          ),
          if (isAndroid) ...[
            ListTile(
              leading: const Icon(Icons.alarm_on_outlined),
              title: Text(l10n.preciseTiming),
              subtitle: Text(exactAllowed ? l10n.preciseTimingOn : l10n.preciseTimingOff),
              trailing: exactAllowed
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.chevron_right),
              onTap: exactAllowed
                  ? null
                  : () async {
                      // Opens system "Alarms & reminders"; on return the
                      // HomeShell resume handler re-checks and refills.
                      await ref.read(notificationServiceProvider).requestExactAlarmPermission();
                      ref.invalidate(exactAlarmAllowedProvider);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.battery_saver_outlined),
              title: Text(l10n.batteryOptimization),
              subtitle: Text(batteryRestricted
                  ? l10n.batteryOptimizationOn
                  : l10n.batteryOptimizationOff),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showBatteryOptimizationDialog(context, ref),
            ),
          ],

          // ------------------------------------------------------- appearance
          _Header(l10n.appearance),
          ListTile(leading: const Icon(Icons.palette_outlined), title: Text(l10n.theme)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (v) => ref.read(themeModeProvider.notifier).set(v.first),
            ),
          ),
          ListTile(leading: const Icon(Icons.language), title: Text(l10n.language)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: '', label: Text(l10n.languageSystem)),
                const ButtonSegment(value: 'en', label: Text('English')),
                const ButtonSegment(value: 'ar', label: Text('العربية')),
              ],
              selected: {ref.watch(localeControllerProvider)?.languageCode ?? ''},
              onSelectionChanged: (v) => ref
                  .read(localeControllerProvider.notifier)
                  .set(v.first.isEmpty ? null : Locale(v.first)),
            ),
          ),

          // ------------------------------------------------------- account
          _Header(l10n.account),
          if (user?.email != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.signedInAs(user!.email!)),
            ),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.logout,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(notificationServiceProvider);
    final repo = ref.read(duaRepositoryProvider);
    if (repo.isEmpty) return;

    if (!await service.areNotificationsEnabled()) {
      if (!await requestNotificationsOrOpenSettings(ref)) return;
    }

    // Prefer the next queued dua so the test shows real content.
    final upcoming = ref.read(scheduleControllerProvider).upcoming;
    final dua = (upcoming.isNotEmpty ? repo.byId(upcoming.first.duaId) : null) ??
        repo.all[Random().nextInt(repo.all.length)];
    try {
      await service.showNow(dua,
          sound: ref.read(reminderSettingsProvider).soundEnabled,
          title: l10n.testNotificationTitle);
      messenger.showSnackBar(SnackBar(content: Text(l10n.testNotificationSent)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errUnknown)));
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.logout)),
        ],
      ),
    );
    if (confirmed != true) return;
    // Stop reminders for the signed-out user, then sign out (AuthGate → Login).
    await ref.read(scheduleControllerProvider.notifier).cancelAll();
    await ref.read(authRepositoryProvider).signOut();
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(text,
          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.minutes, required this.onPicked});
  final String label;
  final int minutes;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        );
        if (picked != null) onPicked(picked.hour * 60 + picked.minute);
      },
      child: Text('$label  ${formatMinutesOfDay(context, minutes)}'),
    );
  }
}
