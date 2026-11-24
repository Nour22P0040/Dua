import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/widgets/arabic_text.dart';
import '../../core/widgets/message_view.dart';
import '../../data/models/dua.dart';
import '../../l10n/app_localizations.dart';
import 'favorites_controller.dart';

/// Full dua view. Also the target of notification taps (payload = dua id).
class DuaDetailScreen extends ConsumerWidget {
  const DuaDetailScreen({super.key, required this.duaId});
  final int duaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dua = ref.watch(duaRepositoryProvider).byId(duaId);
    final favorite = ref.watch(favoritesProvider).contains(duaId);

    if (dua == null) {
      // e.g. the JSON changed after the notification was scheduled.
      return Scaffold(
        appBar: AppBar(),
        body: MessageView(icon: Icons.help_outline, title: l10n.duaNotFound),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dua.title ?? l10n.duaNumber(dua.id)),
        actions: [
          IconButton(
            tooltip: favorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                color: favorite ? Colors.redAccent : null),
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(duaId),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: SelectionArea(child: ArabicText(dua.arabic, fontSize: 28)),
              ),
            ),
            if (dua.transliteration != null)
              _Section(title: l10n.transliteration, text: dua.transliteration!, italic: true),
            if (dua.translation != null)
              _Section(title: l10n.translation, text: dua.translation!),
            if (dua.reference != null)
              _Section(title: l10n.reference, text: dua.reference!),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.copy),
                onPressed: () => _copy(context, dua),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (buttonContext) => FilledButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l10n.share),
                  onPressed: () => _share(buttonContext, dua),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, Dua dua) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: dua.toShareText()));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.copied)));
  }

  Future<void> _share(BuildContext context, Dua dua) async {
    // iPad needs an anchor rect for the share sheet.
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        text: dua.toShareText(),
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text, this.italic = false});
  final String title;
  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          SelectableText(text,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontStyle: italic ? FontStyle.italic : null, height: 1.5)),
        ],
      ),
    );
  }
}
