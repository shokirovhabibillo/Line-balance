import 'package:flutter/material.dart';

import '../data/time_study_history_storage.dart';

class TimeStudyHistoryPage extends StatefulWidget {
  const TimeStudyHistoryPage({super.key});

  @override
  State<TimeStudyHistoryPage> createState() => _TimeStudyHistoryPageState();
}

class _TimeStudyHistoryPageState extends State<TimeStudyHistoryPage> {
  final _storage = TimeStudyHistoryStorage();
  var _loading = true;
  List<TimeStudyHistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _storage.load();
    if (!mounted) return;
    setState(() { _entries = entries; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Study History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Hali saqlangan Time Study tarixi yo‘q.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final data = entry.data;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.timer_outlined)),
                          title: Text(data.sessionName.isEmpty ? 'Nomsiz session' : data.sessionName),
                          subtitle: Text('${data.station.isEmpty ? 'Station ko‘rsatilmagan' : data.station} • ${data.cycles.length} cycle • ${entry.savedAt.toLocal()}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(data.sessionName.isEmpty ? 'Nomsiz session' : data.sessionName),
                              content: Text('Elementlar: ${data.elements.length}\nCyclelar: ${data.cycles.length}\nIshchi: ${data.worker.isEmpty ? '—' : data.worker}'),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish'))],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
