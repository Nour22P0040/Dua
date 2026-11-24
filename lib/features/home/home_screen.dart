import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/arabic_text.dart';
import '../../core/widgets/message_view.dart';
import '../../data/models/dua.dart';
import '../../l10n/app_localizations.dart';
import '../duas/dua_detail_screen.dart';
import '../settings/battery_dialog.dart';
import '../settings/settings_controller.dart';
import 'permission_banner.dart';
import 'schedule_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenDuas});
  final VoidCallback onOpenDuas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.watch(duaRepositoryProvider);
    final status = ref.watch(scheduleControllerProvider);
    final settings = ref.watch(reminderSettingsProvider);
    final notificationsAllowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final exactAllowed = ref.watch(exactAlarmAllowedProvider).value ?? true;
    final batteryRestricted = ref.watch(batteryRestrictedProvider).value ?? false;

    // "Dua of the moment" = last delivered → next queued → first in file.
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final momentId = status.lastDuaId ??
        settingsRepo.lastDuaId ??
        (status.upcoming.isNotEmpty ? status.upcoming.first.duaId : null);
    final Dua? moment =
        (momentId != null ? repo.byId(momentId) : null) ?? repo.all.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: repo.isEmpty
          ? MessageView(
              icon: Icons.menu_book_outlined,
              title: l10n.noDuasLoaded,
              message: repo.result.hasError ? l10n.duasLoadError : null,
            )
          : RefreshIndicator(
              onRefresh: () async {
                refreshPermissionProviders(ref);
                await ref.read(scheduleControllerProvider.notifier).refill();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (!notificationsAllowed) ...[
                    const NotificationPermissionBanner(),
                    const SizedBox(height: 16),
                  ],
                  if (moment != null) _DuaOfMomentCard(dua: moment),
                  const SizedBox(height: 16),
                  _ReminderCard(
                    enabled: settings.enabled,
                    intervalMinutes: settings.intervalMinutes,
                    next: status.enabled ? status.next : null,
                    horizon: status.enabled ? status.horizon : null,
                    queued: status.upcoming.length,
                    exact: exactAllowed,
                    onToggle: (v) => ref
                        .read(reminderSettingsProvider.notifier)
                        .update(settings.copyWith(enabled: v)),
                  ),
                  // Guide users whose reminders may be delayed by Android
                  // battery optimization (only relevant for inexact alarms).
                  if (settings.enabled && batteryRestricted && !exactAllowed) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.battery_alert_outlined),
                        title: Text(l10n.batteryDialogTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showBatteryOptimizationDialog(context, ref),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onOpenDuas,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(l10n.navDuas),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DuaOfMomentCard extends StatelessWidget {
  const _DuaOfMomentCard({required this.dua});
  final Dua dua;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DuaDetailScreen(duaId: dua.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(l10n.duaOfTheMoment,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
              ]),
              const SizedBox(height: 12),
              if (dua.title != null)
                Text(dua.title!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
              ArabicText(dua.arabic,
                  fontSize: 24, color: theme.colorScheme.onPrimaryContainer),
              if (dua.transliteration != null) ...[
                const SizedBox(height: 8),
                Text(dua.transliteration!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onPrimaryContainer)),
              ],
              if (dua.translation != null) ...[
                const SizedBox(height: 8),
                Text(dua.translation!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.enabled,
    required this.intervalMinutes,
    required this.next,
    required this.horizon,
    required this.queued,
    required this.exact,
    required this.onToggle,
  });

  final bool enabled;
  final int intervalMinutes;
  final DateTime? next;
  final DateTime? horizon;
  final int queued;
  final bool exact;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    // How long the queued batch lasts; if short, remind the user to open the app.
    final coverage = horizon?.difference(DateTime.now());
    final showRefillHint =
        enabled && coverage != null && coverage < const Duration(days: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l10n.remindersEnabled, style: theme.textTheme.titleMedium)),
              Switch(value: enabled, onChanged: onToggle),
            ]),
            const Divider(),
            _InfoRow(
              label: l10n.nextReminder,
              value: !enabled
                  ? l10n.remindersOff
                  : next == null
                      ? l10n.noUpcoming
                      : formatReminderTime(context, next!),
              emphasize: true,
            ),
            _InfoRow(label: l10n.currentGap, value: formatInterval(l10n, intervalMinutes)),
            if (enabled) ...[
              const SizedBox(height: 4),
              Text(l10n.scheduledCount(queued), style: muted),
              if (!exact) Text(l10n.inexactNote, style: muted),
              if (showRefillHint)
                Text(l10n.refillHint(formatInterval(l10n, coverage.inMinutes.clamp(1, 1 << 30))),
                    style: muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasize ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
                  ?.copyWith(fontWeight: emphasize ? FontWeight.w600 : null),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
