import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/arabic_normalizer.dart';
import '../../core/widgets/arabic_text.dart';
import '../../core/widgets/message_view.dart';
import '../../data/models/dua.dart';
import '../../l10n/app_localizations.dart';
import 'dua_detail_screen.dart';
import 'favorites_controller.dart';

class DuasListScreen extends ConsumerStatefulWidget {
  const DuasListScreen({super.key});

  @override
  ConsumerState<DuasListScreen> createState() => _DuasListScreenState();
}

class _DuasListScreenState extends ConsumerState<DuasListScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _favoritesOnly = false;

  // Pre-normalized search text per dua id (computed lazily once).
  final Map<int, String> _index = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _searchable(Dua d) => _index.putIfAbsent(
        d.id,
        () => normalizeForSearch([
          d.title,
          d.arabic,
          d.transliteration,
          d.translation,
          d.reference,
          '${d.id}',
        ].whereType<String>().join(' ')),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.watch(duaRepositoryProvider);
    final favorites = ref.watch(favoritesProvider);

    final q = normalizeForSearch(_query);
    final duas = repo.all.where((d) {
      if (_favoritesOnly && !favorites.contains(d.id)) return false;
      return q.isEmpty || _searchable(d).contains(q);
    }).toList();

    Widget body;
    if (repo.isEmpty) {
      body = MessageView(
        icon: Icons.menu_book_outlined,
        title: l10n.noDuasLoaded,
        message: repo.result.hasError ? l10n.duasLoadError : null,
      );
    } else if (duas.isEmpty) {
      body = MessageView(
        icon: _favoritesOnly && q.isEmpty ? Icons.favorite_border : Icons.search_off,
        title: _favoritesOnly && q.isEmpty ? l10n.noFavorites : l10n.noDuasFound,
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: duas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DuaTile(
          dua: duas[i],
          favorite: favorites.contains(duas[i].id),
          onFavorite: () => ref.read(favoritesProvider.notifier).toggle(duas[i].id),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDuas)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _search,
              hintText: l10n.searchDuas,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              ChoiceChip(
                label: Text(l10n.all),
                selected: !_favoritesOnly,
                onSelected: (_) => setState(() => _favoritesOnly = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.favorite, size: 18),
                label: Text('${l10n.favorites} (${favorites.length})'),
                selected: _favoritesOnly,
                onSelected: (_) => setState(() => _favoritesOnly = true),
              ),
            ]),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _DuaTile extends StatelessWidget {
  const _DuaTile({required this.dua, required this.favorite, required this.onFavorite});
  final Dua dua;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DuaDetailScreen(duaId: dua.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text('${dua.id}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(dua.title ?? l10n.duaNumber(dua.id),
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  tooltip: favorite ? l10n.removeFavorite : l10n.addFavorite,
                  icon: Icon(favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? Colors.redAccent : null),
                  onPressed: onFavorite,
                ),
              ]),
              ArabicText(dua.arabic,
                  fontSize: 20, maxLines: 3, textAlign: TextAlign.right),
              if (dua.translation != null) ...[
                const SizedBox(height: 4),
                Text(dua.translation!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
