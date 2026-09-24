import 'package:flutter/material.dart';

import '../../../core/data/app_history.dart';
import '../data/downtime_excel.dart';
import '../data/downtime_models.dart';

class DowntimePage extends StatefulWidget {
  const DowntimePage({super.key});

  @override
  State<DowntimePage> createState() => _DowntimePageState();
}

class _DowntimePageState extends State<DowntimePage> {
  final _storage = DowntimeStorage();
  final _category = TextEditingController(text: 'Equipment');
  final _cause = TextEditingController();
  final _note = TextEditingController();
  bool _productive = false;
  DateTime _start = DateTime.now().subtract(const Duration(minutes: 10));
  DateTime _end = DateTime.now();
  List<DowntimeRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _storage.load();
    if (mounted) setState(() => _records = records);
  }

  Future<void> _pickDateTime(bool start) async {
    final current = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: current,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _add() async {
    final cause = _cause.text.trim();
    if (cause.isEmpty) return;

    final record = DowntimeRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: _category.text.trim(),
      cause: cause,
      start: _start,
      end: _end,
      productive: _productive,
      note: _note.text.trim(),
    );
    final next = [..._records, record];

    await _storage.save(next);
    await AppHistoryStorage().add(
      HistoryEntry(
        module: 'Downtime',
        title: record.cause,
        subtitle: '${record.duration.inMinutes} min • ${record.category}',
        savedAt: DateTime.now(),
      ),
    );

    _cause.clear();
    _note.clear();
    if (mounted) setState(() => _records = next);
  }

  Future<void> _import() async {
    final imported = await DowntimeExcel().importRecords();
    if (imported == null || !mounted) return;
    final next = [..._records, ...imported];
    await _storage.save(next);
    if (mounted) setState(() => _records = next);
  }

  Future<void> _delete(DowntimeRecord record) async {
    final next = _records.where((item) => item.id != record.id).toList();
    await _storage.save(next);
    if (mounted) setState(() => _records = next);
  }

  @override
  void dispose() {
    _category.dispose();
    _cause.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _records.fold<Duration>(
      Duration.zero,
      (sum, record) => sum + record.duration,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Downtime')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: _cause,
            decoration: const InputDecoration(labelText: 'Cause'),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start'),
                  subtitle: Text(_start.toString()),
                  onTap: () => _pickDateTime(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End'),
                  subtitle: Text(_end.toString()),
                  onTap: () => _pickDateTime(false),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Productive / NVA emas'),
            value: _productive,
            onChanged: (value) => setState(() => _productive = value),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Qayd etish'),
              ),
              OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import'),
              ),
              OutlinedButton.icon(
                onPressed: _records.isEmpty
                    ? null
                    : () => DowntimeExcel().export(_records),
                icon: const Icon(Icons.table_view),
                label: const Text('Excel'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Jami downtime'),
              subtitle: Text(
                '${total.inMinutes} min ${total.inSeconds % 60} s',
              ),
              trailing: Text('${_records.length} yozuv'),
            ),
          ),
          ..._records.reversed.map(
            (record) => Card(
              child: ListTile(
                title: Text(record.cause),
                subtitle: Text(
                  '${record.category} • ${record.duration.inMinutes} min • '
                  '${record.productive ? 'Productive' : 'NVA'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(record),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
