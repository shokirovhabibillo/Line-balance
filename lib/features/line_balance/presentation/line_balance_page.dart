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
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await _storage.load(); if (mounted) setState(() => _plans = p); }
  void _addStation() { final w = double.tryParse(_workload.text.replaceAll(',', '.')); if (_station.text.trim().isEmpty || w == null) return; setState(() { _stations = [..._stations, LineBalanceStation(id: DateTime.now().microsecondsSinceEpoch.toString(), sequence: _stations.length + 1, name: _station.text.trim(), workloadSeconds: w, operator: _operator.text.trim())]; _station.clear(); _workload.clear(); _operator.clear(); }); }
  Future<void> _save() async {
    final takt = double.tryParse(_takt.text.replaceAll(',', '.')) ?? 0;
    final plan = LineBalancePlan(id: DateTime.now().microsecondsSinceEpoch.toString(), name: _name.text.trim().isEmpty ? 'Line Balance' : _name.text.trim(), taktSeconds: takt, demandPerDay: double.tryParse(_demand.text.replaceAll(',', '.')) ?? 0, availableSeconds: double.tryParse(_available.text.replaceAll(',', '.')) ?? 0, stations: List.unmodifiable(_stations));
    final next = [..._plans, plan]; await _storage.save(next); await AppHistoryStorage().add(HistoryEntry(module: 'Line Balance', title: plan.name, subtitle: 'Balance ${plan.balancePercent.toStringAsFixed(1)}%')); if (mounted) setState(() => _plans = next);
  }

  @override
  void dispose() { for (final c in [_name, _takt, _demand, _available, _station, _workload, _operator]) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final takt = double.tryParse(_takt.text.replaceAll(',', '.')) ?? 0;
    final temp = LineBalancePlan(id: '', name: '', taktSeconds: takt, stations: _stations);
    return Scaffold(appBar: AppBar(title: const Text('Line Balance')), body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Plan nomi')),
      Row(children: [Expanded(child: TextField(controller: _takt, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Takt Time (s)'))), const SizedBox(width: 12), Expanded(child: TextField(controller: _demand, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Demand / day'))), const SizedBox(width: 12), Expanded(child: TextField(controller: _available, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available Time (s)')))]),
      const SizedBox(height: 16), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Station / workload', style: Theme.of(context).textTheme.titleMedium), Row(children: [Expanded(child: TextField(controller: _station, decoration: const InputDecoration(labelText: 'Station'))), const SizedBox(width: 8), Expanded(child: TextField(controller: _workload, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Workload (s)'))), const SizedBox(width: 8), Expanded(child: TextField(controller: _operator, decoration: const InputDecoration(labelText: 'Operator'))), IconButton(onPressed: _addStation, icon: const Icon(Icons.add_circle))]), ..._stations.map((s) => ListTile(dense: true, leading: CircleAvatar(child: Text('${s.sequence}')), title: Text(s.name), subtitle: Text('${s.workloadSeconds.toStringAsFixed(2)} s • ${s.operator}'), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _stations = _stations.where((x) => x.id != s.id).toList()))))])),
      const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 10, children: [Chip(label: Text('Total: ${temp.totalWorkload.toStringAsFixed(2)} s')), Chip(label: Text('Bottleneck: ${temp.bottleneck.toStringAsFixed(2)} s')), Chip(label: Text('Balance: ${temp.balancePercent.toStringAsFixed(1)}%')), Chip(label: Text('Theory stations: ${temp.theoreticalStations}'))]),
      const SizedBox(height: 12), Row(children: [Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Saqlash'))), const SizedBox(width: 10), OutlinedButton.icon(onPressed: () => LineBalanceExcel().importPlan().then((p) { if (p != null && mounted) setState(() { _plans = [..._plans, p]; _takt.text = p.taktSeconds.toString(); _stations = p.stations; }); }), icon: const Icon(Icons.file_open_outlined), label: const Text('Import')), const SizedBox(width: 10), OutlinedButton.icon(onPressed: _plans.isEmpty ? null : () => LineBalanceExcel().export(_plans.last), icon: const Icon(Icons.table_view), label: const Text('Excel'))]),
      const SizedBox(height: 24), Text('Saqlangan rejalar', style: Theme.of(context).textTheme.titleLarge), ..._plans.reversed.map((p) => Card(child: ListTile(title: Text(p.name), subtitle: Text('${p.stations.length} station • Balance ${p.balancePercent.toStringAsFixed(1)}%'), trailing: IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () => LineBalanceExcel().export(p))))),
    ]));
  }
}
