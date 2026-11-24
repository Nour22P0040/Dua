import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../home/schedule_controller.dart';

/// Explains Android battery optimization / OEM background killers and offers
/// to exempt the app (or open its settings for Autostart etc.).
Future<void> showBatteryOptimizationDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.battery_alert_outlined),
      title: Text(l10n.batteryDialogTitle),
      content: SingleChildScrollView(child: Text(l10n.batteryDialogBody)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openAppSettings();
          },
          child: Text(l10n.openSettings),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(batteryServiceProvider).requestUnrestricted();
            ref.invalidate(batteryRestrictedProvider);
          },
          child: Text(l10n.allow),
        ),
      ],
    ),
  );
}
