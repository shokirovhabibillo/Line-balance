import 'package:flutter/material.dart';

import '../../../core/data/app_history.dart';
import '../data/line_balance_excel.dart';
import '../data/line_balance_models.dart';

class LineBalancePage extends StatefulWidget {
  const LineBalancePage({super.key});

  @override
  State<LineBalancePage> createState() => _LineBalancePageState();
}

class _LineBalancePageState extends State<LineBalancePage> {
  final _storage = LineBalanceStorage();
  final _name = TextEditingController(text: 'Yangi Line Balance');
  final _takt = TextEditingController(text: '60');
  final _demand = TextEditingController();
  final _available = TextEditingController();
  final _station = TextEditingController();
  final _workload = TextEditingController();
  final _operator = TextEditingController();
  List<LineBalancePlan> _plans = [];
  List<LineBalanceStation> _stations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _storage.load();
    if (mounted) setState(() => _plans = plans);
  }

  double _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  void _addStation() {
    final name = _station.text.trim();
    final workload = _number(_workload.text);
    if (name.isEmpty || workload <= 0) return;

    setState(() {
      _stations = [
        ..._stations,
        LineBalanceStation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sequence: _stations.length + 1,
          name: name,
          workloadSeconds: workload,
          operator: _operator.text.trim(),
        ),
      ];
    });
    _station.clear();
    _workload.clear();
    _operator.clear();
  }

  Future<void> _save() async {
    final plan = LineBalancePlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim().isEmpty ? 'Line Balance' : _name.text.trim(),
      taktSeconds: _number(_takt.text),
      demandPerDay: _number(_demand.text),
      availableSeconds: _number(_available.text),
      stations: List.unmodifiable(_stations),
    );
    final next = [..._plans, plan];
    await _storage.save(next);
    await AppHistoryStorage().add(
      HistoryEntry(
        module: 'Line Balance',
        title: plan.name,
        subtitle: 'Balance ${plan.balancePercent.toStringAsFixed(1)}%',
        savedAt: DateTime.now(),
      ),
    );
    if (mounted) setState(() => _plans = next);
  }

  Future<void> _import() async {
    final plan = await LineBalanceExcel().importPlan();
    if (plan == null || !mounted) return;
    setState(() {
      _plans = [..._plans, plan];
      _name.text = plan.name;
      _takt.text = plan.taktSeconds.toString();
      _demand.text = plan.demandPerDay.toString();
      _available.text = plan.availableSeconds.toString();
      _stations = plan.stations;
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _takt,
      _demand,
      _available,
      _station,
      _workload,
      _operator,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temp = LineBalancePlan(
      id: '',
      name: '',
      taktSeconds: _number(_takt.text),
      stations: _stations,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Line Balance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Plan nomi'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _takt,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Takt Time (s)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _demand,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Demand / day'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _available,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Available Time (s)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station / workload',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _station,
                          decoration:
                              const InputDecoration(labelText: 'Station'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _workload,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Workload (s)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _operator,
                          decoration:
                              const InputDecoration(labelText: 'Operator'),
                        ),
                      ),
                      IconButton(
                        onPressed: _addStation,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                  ..._stations.map(
                    (station) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        child: Text('${station.sequence}'),
                      ),
                      title: Text(station.name),
                      subtitle: Text(
                        '${station.workloadSeconds.toStringAsFixed(2)} s'
                        '${station.operator.isEmpty ? '' : ' • ${station.operator}'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            _stations = _stations
                                .where((item) => item.id != station.id)
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
                  'Total: ${temp.totalWorkload.toStringAsFixed(2)} s',
                ),
              ),
              Chip(
                label: Text(
                  'Bottleneck: ${temp.bottleneck.toStringAsFixed(2)} s',
                ),
              ),
              Chip(
                label: Text(
                  'Balance: ${temp.balancePercent.toStringAsFixed(1)}%',
                ),
              ),
              Chip(
                label: Text('Theory stations: ${temp.theoreticalStations}'),
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
                onPressed: _plans.isEmpty
                    ? null
                    : () => LineBalanceExcel().export(_plans.last),
                icon: const Icon(Icons.table_view),
                label: const Text('Excel'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Saqlangan rejalar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ..._plans.reversed.map(
            (plan) => Card(
              child: ListTile(
                title: Text(plan.name),
                subtitle: Text(
                  '${plan.stations.length} station • '
                  'Balance ${plan.balancePercent.toStringAsFixed(1)}%',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => LineBalanceExcel().export(plan),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
