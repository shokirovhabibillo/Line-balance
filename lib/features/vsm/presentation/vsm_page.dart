import 'package:flutter/material.dart';

import '../../../core/data/app_history.dart';
import '../data/vsm_excel.dart';
import '../data/vsm_models.dart';

class VsmPage extends StatefulWidget {
  const VsmPage({super.key});

  @override
  State<VsmPage> createState() => _VsmPageState();
}

class _VsmPageState extends State<VsmPage> {
  final _storage = VsmStorage();
  final _name = TextEditingController(text: 'Yangi VSM');
  final _demand = TextEditingController();
  final _process = TextEditingController();
  final _ct = TextEditingController();
  final _co = TextEditingController();
  final _uptime = TextEditingController(text: '100');
  final _wip = TextEditingController();
  final _lead = TextEditingController();
  bool _va = true;
  String _state = 'Current State';
  List<VsmMap> _maps = [];
  List<VsmProcess> _processes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final maps = await _storage.load();
    if (mounted) setState(() => _maps = maps);
  }

  double _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  void _addProcess() {
    final name = _process.text.trim();
    final ct = _number(_ct.text);
    if (name.isEmpty || ct <= 0) return;

    setState(() {
      _processes = [
        ..._processes,
        VsmProcess(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sequence: _processes.length + 1,
          name: name,
          cycleTimeSeconds: ct,
          changeoverSeconds: _number(_co.text),
          uptimePercent: _number(_uptime.text) == 0 ? 100 : _number(_uptime.text),
          wip: _number(_wip.text),
          leadTimeSeconds: _number(_lead.text),
          valueAdd: _va,
        ),
      ];
    });

    _process.clear();
    _ct.clear();
    _co.clear();
    _wip.clear();
    _lead.clear();
  }

  Future<void> _save() async {
    final map = VsmMap(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim().isEmpty ? 'VSM' : _name.text.trim(),
      customerDemandPerDay: _number(_demand.text),
      state: _state,
      processes: List.unmodifiable(_processes),
    );
    final next = [..._maps, map];

    await _storage.save(next);
    await AppHistoryStorage().add(
      HistoryEntry(
        module: 'VSM',
        title: map.name,
        subtitle: 'VA/Lead ${map.vaRatio.toStringAsFixed(1)}%',
        savedAt: DateTime.now(),
      ),
    );
    if (mounted) setState(() => _maps = next);
  }

  Future<void> _import() async {
    final map = await VsmExcel().importMap();
    if (map == null || !mounted) return;
    setState(() {
      _processes = map.processes;
      _name.text = map.name;
      _state = map.state;
      _demand.text = map.customerDemandPerDay.toString();
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _demand,
      _process,
      _ct,
      _co,
      _uptime,
      _wip,
      _lead,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temp = VsmMap(id: '', name: '', processes: _processes);

    return Scaffold(
      appBar: AppBar(title: const Text('VSM')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Map nomi'),
          ),
          TextField(
            controller: _demand,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Customer demand / day',
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'Current State',
                label: Text('Current State'),
              ),
              ButtonSegment<String>(
                value: 'Future State',
                label: Text('Future State'),
              ),
            ],
            selected: {_state},
            onSelectionChanged: (value) {
              setState(() => _state = value.first);
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Process',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _process,
                    decoration: const InputDecoration(
                      labelText: 'Process nomi',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ct,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'CT (s)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _co,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'C/O (s)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _uptime,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Uptime %'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _wip,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'WIP'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lead,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Lead Time (s)',
                          ),
                        ),
                      ),
                      Checkbox(
                        value: _va,
                        onChanged: (value) =>
                            setState(() => _va = value ?? true),
                      ),
                      const Text('VA'),
                      IconButton(
                        onPressed: _addProcess,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                  ..._processes.map(
                    (process) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        child: Text('${process.sequence}'),
                      ),
                      title: Text(process.name),
                      subtitle: Text(
                        'CT ${process.cycleTimeSeconds.toStringAsFixed(1)} s • '
                        'Lead ${process.leadTimeSeconds.toStringAsFixed(1)} s • '
                        '${process.valueAdd ? 'VA' : 'NVA'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            _processes = _processes
                                .where((item) => item.id != process.id)
                                .toList();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                label: Text(
                  'CT ${temp.totalCycleTime.toStringAsFixed(1)} s',
                ),
              ),
              Chip(
                label: Text(
                  'Lead ${temp.totalLeadTime.toStringAsFixed(1)} s',
                ),
              ),
              Chip(
                label: Text('VA ${temp.valueAddTime.toStringAsFixed(1)} s'),
              ),
              Chip(
                label: Text('VA ratio ${temp.vaRatio.toStringAsFixed(1)}%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Saqlash'),
              ),
              OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import'),
              ),
              OutlinedButton.icon(
                onPressed: _maps.isEmpty
                    ? null
                    : () => VsmExcel().export(_maps.last),
                icon: const Icon(Icons.table_view),
                label: const Text('Excel'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Saqlangan VSM',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ..._maps.reversed.map(
            (map) => Card(
              child: ListTile(
                title: Text(map.name),
                subtitle: Text(
                  '${map.processes.length} process • '
                  'VA ratio ${map.vaRatio.toStringAsFixed(1)}%',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => VsmExcel().export(map),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
