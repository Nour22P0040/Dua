import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../duas/dua_detail_screen.dart';
import '../duas/duas_list_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';
import 'schedule_controller.dart';

/// Signed-in shell with bottom navigation.
///
/// Responsibilities beyond layout:
///  * asks for notification permission once per sign-in;
///  * refills the notification batch on mount and every app resume;
///  * opens DuaDetailScreen when a notification is tapped (cold start or
///    while running) — NotificationService publishes the id in `tappedDuaId`.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  late final ValueNotifier<int?> _tapped;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tapped = ref.read(notificationServiceProvider).tappedDuaId;
    _tapped.addListener(_openTappedDua);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapped.removeListener(_openTappedDua);
    super.dispose();
  }

  Future<void> _onFirstFrame() async {
    _openTappedDua(); // handles the cold-start tap
    final notifications = ref.read(notificationServiceProvider);
    if (!await notifications.areNotificationsEnabled()) {
      await notifications.requestNotificationPermission();
      if (mounted) refreshPermissionProviders(ref);
    }
    await ref.read(scheduleControllerProvider.notifier).refill();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User may be back from system settings, or reminders may have fired.
      refreshPermissionProviders(ref);
      ref.read(scheduleControllerProvider.notifier).refill();
    }
  }

  void _openTappedDua() {
    final id = _tapped.value;
    if (id == null || !mounted) return;
    _tapped.value = null;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DuaDetailScreen(duaId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenDuas: () => setState(() => _tab = 1)),
          const DuasListScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.navHome),
          NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: l10n.navDuas),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: l10n.navSettings),
        ],
      ),
    );
  }
}
