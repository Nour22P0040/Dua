import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'schedule_controller.dart';

/// Shown when notifications are blocked. First tries the OS prompt; if the
/// user denied it before (the OS won't prompt again) opens app settings.
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.notifications_off_outlined, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.notificationsDisabledTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: scheme.onErrorContainer)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(l10n.notificationsDisabledBody,
                style: TextStyle(color: scheme.onErrorContainer)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton(
                onPressed: () => requestNotificationsOrOpenSettings(ref),
                child: Text(l10n.enableNotifications),
              ),
              TextButton(
                onPressed: openAppSettings,
                child: Text(l10n.openSettings),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

Future<bool> requestNotificationsOrOpenSettings(WidgetRef ref) async {
  final service = ref.read(notificationServiceProvider);
  final granted = await service.requestNotificationPermission();
  if (!granted) await openAppSettings();
  refreshPermissionProviders(ref);
  if (granted) await ref.read(scheduleControllerProvider.notifier).refill();
  return granted;
}
