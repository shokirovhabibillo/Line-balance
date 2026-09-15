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
  final _cycles = <CycleRecord>[];
  final _elements = <WorkElement>[];
  final _currentElementRecords = <ElementRecord>[];

  WorkType _workType = WorkType.cyclic;
  Timer? _refreshTimer;
  final _cycleStopwatch = Stopwatch();
  final _elementStopwatch = Stopwatch();

  bool _runningCycle = false;
  bool _runningElement = false;
  int _elementIndex = 0;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _startCycle() {
    if (_runningCycle) return;

    _currentElementRecords.clear();
    _elementIndex = 0;

    _cycleStopwatch
      ..reset()
      ..start();

    _runningCycle = true;
    _startRefresh();
    setState(() {});
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  void _startElement() {
    if (!_runningCycle ||
        _runningElement ||
        _elementIndex >= _elements.length) {
      return;
    }

    _elementStopwatch
      ..reset()
      ..start();

    _runningElement = true;
    setState(() {});
  }

  void _finishElement() {
    if (!_runningElement) return;

    _elementStopwatch.stop();
    final duration = _elementStopwatch.elapsed;
    final element = _elements[_elementIndex];

    if (duration > Duration.zero) {
      _currentElementRecords.add(
        ElementRecord(
          elementId: element.id,
          duration: duration,
          recordedAt: DateTime.now(),
        ),
      );
    }

    _runningElement = false;
    _elementIndex++;
    _elementStopwatch.reset();
    setState(() {});
  }

  bool get _allElementsMeasured {
    return _elements.isEmpty || _elementIndex >= _elements.length;
  }

  void _finishCycle() {
    if (!_runningCycle || _runningElement || !_allElementsMeasured) {
      return;
    }

    _cycleStopwatch.stop();
    _refreshTimer?.cancel();

    final duration = _cycleStopwatch.elapsed;

    if (duration > Duration.zero) {
      _cycles.add(
        CycleRecord(
          number: _cycles.length + 1,
          duration: duration,
          recordedAt: DateTime.now(),
          elements: List.unmodifiable(_currentElementRecords),
        ),
      );
    }

    _runningCycle = false;
    _elementIndex = 0;
    _currentElementRecords.clear();
    _cycleStopwatch.reset();
    _elementStopwatch.reset();
    setState(() {});
  }

  void _resetCycle() {
    _refreshTimer?.cancel();
    _cycleStopwatch
      ..stop()
      ..reset();
    _elementStopwatch
      ..stop()
      ..reset();

    _runningCycle = false;
    _runningElement = false;
    _elementIndex = 0;
    _currentElementRecords.clear();
    setState(() {});
  }

  Future<String?> _askElementName({
    String? initial,
    required String title,
    required String action,
  }) async {
    final controller = TextEditingController(text: initial);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Element nomi'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _addElement() async {
    final name = await _askElementName(
      title: 'Ish elementi qo‘shish',
      action: 'Qo‘shish',
    );
    if (name == null) return;

    setState(() {
      _elements.add(
        WorkElement(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          type: WorkElementType.productive,
        ),
      );
    });
  }

  Future<void> _editElement(int index) async {
    final element = _elements[index];
    final name = await _askElementName(
      initial: element.name,
      title: 'Ish elementini tahrirlash',
      action: 'Saqlash',
    );
    if (name == null) return;

    setState(() {
      _elements[index] = element.copyWith(name: name);
    });
  }

  void _deleteElement(int index) {
    if (_runningCycle) return;
    setState(() => _elements.removeAt(index));
  }

  void _toggleElementType(int index) {
    if (_runningCycle) return;

    final element = _elements[index];
    setState(() {
      _elements[index] = element.copyWith(
        type: element.type == WorkElementType.productive
            ? WorkElementType.nonProductive
            : WorkElementType.productive,
      );
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final t = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '${d.inHours.toString().padLeft(2, '0')}:$m:$s.$t';
  }

  String _elementName(String id) {
    for (final element in _elements) {
      if (element.id == id) return element.name;
    }
    return 'Noma’lum element';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _calculator.summarize(_cycles);
    final elementSummaries =
        _calculator.summarizeElements(_cycles, _elements);

    String fmt(Duration? d) => d == null ? '—' : _format(d);

    return Scaffold(
      appBar: AppBar(title: const Text('Time Study')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Xronometraj sessiyasi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cycle va cycle ichidagi ish elementlarini mustaqil timerlar bilan o‘lchash.',
          ),
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
              ButtonSegment(
                value: WorkType.cyclic,
                label: Text('Siklik'),
                icon: Icon(Icons.repeat),
              ),
              ButtonSegment(
                value: WorkType.nonCyclic,
                label: Text('Nosiklik'),
                icon: Icon(Icons.shuffle),
              ),
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
                  Text(
                    _format(_runningElement
                        ? _elementStopwatch.elapsed
                        : _cycleStopwatch.elapsed),
                    key: const Key('time_study_timer'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _runningElement
                        ? 'Element ${_elementIndex + 1} / ${_elements.length}'
                        : _runningCycle
                            ? (_elements.isEmpty
                                ? 'Cycle davom etmoqda'
                                : _allElementsMeasured
                                    ? 'Barcha elementlar o‘lchandi'
                                    : 'Keyingi elementni boshlang')
                            : 'Yangi cycle boshlashga tayyor',
                    key: const Key('time_study_status'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _runningCycle ? null : _startCycle,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start cycle'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _runningCycle &&
                                !_runningElement &&
                                _elementIndex < _elements.length
                            ? _startElement
                            : null,
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(
                          _elements.isEmpty
                              ? 'Element yo‘q'
                              : 'Start element ${_elementIndex + 1}',
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _runningElement ? _finishElement : null,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Finish element'),
                      ),
                      FilledButton.icon(
                        onPressed: _runningCycle &&
                                !_runningElement &&
                                _allElementsMeasured
                            ? _finishCycle
                            : null,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Finish cycle'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _runningCycle ? _resetCycle : null,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                  if (_elements.isNotEmpty && _runningCycle) ...[
                    const SizedBox(height: 14),
                    Text(
                      _allElementsMeasured
                          ? 'Barcha elementlar o‘lchandi. Finish cycle bosing.'
                          : 'Navbatdagi element: ${_elements[_elementIndex].name}',
                      textAlign: TextAlign.center,
                    ),
                  ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ish elementlari (${_elements.length})',
                  key: const Key('work_elements_header'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _runningCycle ? null : _addElement,
                icon: const Icon(Icons.add),
                label: const Text('Qo‘shish'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_elements.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Ishni o‘lchanadigan elementlarga ajrating. Element qo‘shilgach, cycle ichida har birini alohida o‘lchash mumkin.',
                ),
              ),
            )
          else
            ..._elements.asMap().entries.map(
              (e) {
                final element = e.value;
                final elementSummary = elementSummaries[e.key];

                return Card(
                  key: ValueKey(element.id),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${e.key + 1}')),
                    title: Text(element.name),
                    subtitle: Text(
                      '${element.type == WorkElementType.productive ? 'Samarali ish' : 'Samarasiz ish'}'
                      ' • ${elementSummary.count} ta o‘lchov'
                      ' • O‘rtacha: ${fmt(elementSummary.average)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editElement(e.key);
                        if (value == 'type') _toggleElementType(e.key);
                        if (value == 'delete') _deleteElement(e.key);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Tahrirlash'),
                        ),
                        PopupMenuItem(
                          value: 'type',
                          child: Text(
                            element.type == WorkElementType.productive
                                ? 'Samarasizga o‘tkazish'
                                : 'Samaraliga o‘tkazish',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('O‘chirish'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Text(
            'Cycle yozuvlari (${_cycles.length})',
            key: const Key('cycle_records_header'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (_cycles.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Hali cycle yozilmagan. Start cycle → Finish cycle orqali o‘lchang.',
                ),
              ),
            )
          else
            ..._cycles.map(
              (cycle) => Card(
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text('${cycle.number}')),
                  title: Text(_format(cycle.duration)),
                  subtitle: Text(
                    '${cycle.elements.length} ta element o‘lchangan',
                  ),
                  children: [
                    if (cycle.elements.isEmpty)
                      const ListTile(
                        title: Text(
                          'Bu cycle uchun element o‘lchovlari yo‘q.',
                        ),
                      )
                    else
                      ...cycle.elements.map(
                        (record) => ListTile(
                          dense: true,
                          title: Text(_elementName(record.elementId)),
                          trailing: Text(_format(record.duration)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
