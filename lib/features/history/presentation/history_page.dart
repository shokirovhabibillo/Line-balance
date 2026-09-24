import 'package:flutter/material.dart';

import '../../../core/data/app_history.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _storage = AppHistoryStorage();
  List<HistoryEntry> _items = [];
  String _filter = 'All';

  static const _modules = <String>[
    'All',
    'Time Study',
    'Catalog',
    'Line Balance',
    'VSM',
    'Downtime',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.load();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _items
        : _items.where((entry) => entry.module == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Global History')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _modules
                  .map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(module),
                        selected: _filter == module,
                        onSelected: (_) {
                          setState(() => _filter = module);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('History hozircha bo‘sh'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final entry = filtered[index];
                      final date = entry.savedAt.toLocal();
                      final dateText =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
                          '${date.day.toString().padLeft(2, '0')} '
                          '${date.hour.toString().padLeft(2, '0')}:'
                          '${date.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            entry.module.isEmpty
                                ? '?'
                                : entry.module.substring(0, 1),
                          ),
                        ),
                        title: Text(entry.title),
                        subtitle: Text(
                          '${entry.module} • ${entry.subtitle}',
                        ),
                        trailing: Text(dateText),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
