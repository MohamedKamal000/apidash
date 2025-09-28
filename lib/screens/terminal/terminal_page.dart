import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/terminal/models.dart';
import '../../consts.dart';
import '../../providers/terminal_providers.dart';
import '../../providers/collection_providers.dart';
import '../../widgets/button_copy.dart';
import '../../widgets/field_search.dart';
import '../../widgets/terminal_tiles.dart';
import '../../widgets/empty_message.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import '../../widgets/terminal_level_filter_menu.dart';

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key});

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showTimestamps = false; // user toggle

  // Initially all levels will be selected
  final Set<TerminalLevel> _selectedLevels = {
    TerminalLevel.debug,
    TerminalLevel.info,
    TerminalLevel.warn,
    TerminalLevel.error,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(terminalStateProvider);
    final collection = ref.watch(collectionStateNotifierProvider);
    final allEntries = state.entries;
    final filtered = _applyFilters(allEntries);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchCtrl,
                    hintText: 'Search logs',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button
                TerminalLevelFilterMenu(
                  selected: _selectedLevels,
                  onChanged: (set) => setState(() {
                    _selectedLevels
                      ..clear()
                      ..addAll(set);
                  }),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Show timestamps',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: _showTimestamps,
                        onChanged: (v) =>
                            setState(() => _showTimestamps = v ?? false),
                      ),
                      const Text('Timestamp', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),

                const Spacer(),
                // Clear button
                ADIconButton(
                  tooltip: 'Clear logs',
                  icon: Icons.delete_outline,
                  iconSize: 22,
                  onPressed: () {
                    ref.read(terminalStateProvider.notifier).clear();
                  },
                ),
                const SizedBox(width: 4),
                // Copy all button
                CopyButton(
                  showLabel: false,
                  toCopy: ref
                      .read(terminalStateProvider.notifier)
                      .serializeAll(entries: allEntries),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: EmptyMessage(
                      title: 'No logs yet',
                      subtitle:
                          'Send a request to see details here in the console',
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final e = filtered[filtered.length - 1 - i];
                      final searchQuery = _searchCtrl.text.trim();
                      String requestName = '';
                      if (e.source == TerminalSource.js &&
                          e.requestId != null) {
                        final model = collection?[e.requestId];
                        if (model != null) {
                          requestName =
                              model.name.isNotEmpty ? model.name : 'Untitled';
                        }
                      } else if (e.requestId != null) {
                        final model = collection?[e.requestId];
                        if (model != null) {
                          requestName =
                              model.name.isNotEmpty ? model.name : 'Untitled';
                        }
                      }
                      switch (e.source) {
                        case TerminalSource.js:
                          return JsLogTile(
                            entry: e,
                            showTimestamp: _showTimestamps,
                            searchQuery: searchQuery,
                            requestName:
                                requestName.isNotEmpty ? requestName : null,
                          );
                        case TerminalSource.network:
                          return NetworkLogTile(
                            entry: e,
                            showTimestamp: _showTimestamps,
                            searchQuery: searchQuery,
                            requestName:
                                requestName.isNotEmpty ? requestName : null,
                          );
                        case TerminalSource.system:
                          return SystemLogTile(
                            entry: e,
                            showTimestamp: _showTimestamps,
                            searchQuery: searchQuery,
                          );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<TerminalEntry> _applyFilters(List<TerminalEntry> entries) {
    final q = _searchCtrl.text.trim().toLowerCase();
    bool matches(TerminalEntry e) {
      if (!_selectedLevels.contains(e.level)) return false;
      if (q.isEmpty) return true;
      final controller = ref.read(terminalStateProvider.notifier);
      final title = controller.titleFor(e).toLowerCase();
      final sub = (controller.subtitleFor(e) ?? '').toLowerCase();
      return title.contains(q) || sub.contains(q);
    }

    return entries.where(matches).toList(growable: false);
  }
}
