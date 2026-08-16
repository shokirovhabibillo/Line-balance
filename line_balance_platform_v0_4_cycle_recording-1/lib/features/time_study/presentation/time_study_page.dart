import 'dart:async';
import 'package:flutter/material.dart';
import '../application/time_study_calculator.dart';
import '../domain/time_study_models.dart';

class TimeStudyPage extends StatefulWidget {
  const TimeStudyPage({super.key});
  @override
  State<TimeStudyPage> createState() => _TimeStudyPageState();
}

class _TimeStudyPageState extends State<TimeStudyPage> {
  final _nameController = TextEditingController();
  final _calculator = const TimeStudyCalculator();
  WorkType _workType = WorkType.cyclic;
  final _cycles = <CycleRecord>[];
  final _elements = <WorkElement>[];
  Timer? _timer;
  final _stopwatch = Stopwatch();
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    _stopwatch
      ..reset()
      ..start();
    _running = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _finish() {
    if (!_running) return;
    _stopwatch.stop();
    _timer?.cancel();
    final duration = _stopwatch.elapsed;
    if (duration > Duration.zero) {
      _cycles.add(CycleRecord(
        number: _cycles.length + 1,
        duration: duration,
        recordedAt: DateTime.now(),
      ));
    }
    _running = false;
    _stopwatch.reset();
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _running = false;
    setState(() {});
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final t = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '${d.inHours.toString().padLeft(2, '0')}:$m:$s.$t';
  }

  void _addElement() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ish elementi qo‘shish'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Element nomi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _elements.add(WorkElement(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name,
                  type: WorkElementType.productive,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Qo‘shish'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _calculator.summarize(_cycles);
    String fmt(Duration? d) => d == null ? '—' : _format(d);

    return Scaffold(
      appBar: AppBar(title: const Text('Time Study')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Xronometraj sessiyasi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Cycle vaqtlarini ketma-ket yozib borish. Rating, allowance va Standard Time keyingi bosqichda qo‘shiladi.'),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Sessiya nomi',
              hintText: 'Masalan: ST-03 yig‘ish jarayoni',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<WorkType>(
            segments: const [
              ButtonSegment(value: WorkType.cyclic, label: Text('Siklik'), icon: Icon(Icons.repeat)),
              ButtonSegment(value: WorkType.nonCyclic, label: Text('Nosiklik'), icon: Icon(Icons.shuffle)),
            ],
            selected: {_workType},
            onSelectionChanged: (v) => setState(() => _workType = v.first),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(_format(_stopwatch.elapsed),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _running ? null : _start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start cycle'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _running ? _finish : null,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Finish cycle'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _running ? _reset : null,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  _Metric('Cycles', '${summary.count}'),
                  _Metric('Average', fmt(summary.average)),
                  _Metric('Min', fmt(summary.minimum)),
                  _Metric('Max', fmt(summary.maximum)),
                  _Metric('Range', fmt(summary.range)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Cycle yozuvlari (${_cycles.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_cycles.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Hali cycle yozilmagan. Start cycle → Finish cycle orqali o‘lchang.'),
            ))
          else
            ..._cycles.asMap().entries.map((e) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${e.value.number}')),
                title: Text(_format(e.value.duration)),
                subtitle: const Text('Cycle time'),
                trailing: IconButton(
                  onPressed: () => setState(() {
                    _cycles.removeAt(e.key);
                    for (var i = 0; i < _cycles.length; i++) {
                      final c = _cycles[i];
                      _cycles[i] = CycleRecord(number: i + 1, duration: c.duration, recordedAt: c.recordedAt);
                    }
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            )),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Ish elementlari (${_elements.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
              FilledButton.tonalIcon(onPressed: _addElement, icon: const Icon(Icons.add), label: const Text('Qo‘shish')),
            ],
          ),
          const SizedBox(height: 8),
          if (_elements.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Ishni o‘lchanadigan elementlarga ajrating.'),
            ))
          else
            ..._elements.asMap().entries.map((e) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${e.key + 1}')),
                title: Text(e.value.name),
                subtitle: Text(e.value.type == WorkElementType.productive ? 'Samarali ish' : 'Samarasiz ish'),
              ),
            )),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 100,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    ]),
  );
}
