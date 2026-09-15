import 'dart:async';

import 'package:flutter/material.dart';

import '../application/time_study_calculator.dart';
import '../data/time_study_storage.dart';
import '../domain/time_study_models.dart';

class TimeStudyPage extends StatefulWidget {
  const TimeStudyPage({super.key});

  @override
  State<TimeStudyPage> createState() => _TimeStudyPageState();
}

class _TimeStudyPageState extends State<TimeStudyPage> {
  final _nameController = TextEditingController();
  final _calculator = const TimeStudyCalculator();
  final _storage = const TimeStudyStorage();
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
  bool _loadingSession = true;
  Future<void> _saveChain = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_queueSave);
    _loadSession();
  }

  Future<void> _loadSession() async {
    final data = await _storage.load();
    if (!mounted) return;

    if (data != null) {
      _nameController.text = data.sessionName;
      _workType = data.workType;
      _elements
        ..clear()
        ..addAll(data.elements);
      _cycles
        ..clear()
        ..addAll(data.cycles);
    }

    _loadingSession = false;
    setState(() {});
  }

  void _queueSave() {
    if (_loadingSession) return;

    final data = TimeStudySessionData(
      sessionName: _nameController.text.trim(),
      workType: _workType,
      elements: List.unmodifiable(_elements),
      cycles: List.unmodifiable(_cycles),
    );

    _saveChain = _saveChain.then((_) => _storage.save(data));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.removeListener(_queueSave);
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
    _queueSave();
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
    _queueSave();
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

  Future<_ElementDraft?> _showElementDialog({WorkElement? initial}) async {
    final nameController = TextEditingController(text: initial?.name);
    final basisController = TextEditingController(text: initial?.basis);
    var type = initial?.type ?? WorkElementType.productive;
    final requirements = <WorkRequirement>{...?initial?.requirements};
    final verificationMethods = <VerificationMethod>{
      ...?initial?.verificationMethods,
    };

    final result = await showDialog<_ElementDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final noRequirementSelected = requirements.isEmpty;

            void toggleRequirement(WorkRequirement value) {
              setDialogState(() {
                if (value == WorkRequirement.none) return;
                if (requirements.contains(value)) {
                  requirements.remove(value);
                } else {
                  requirements.add(value);
                }
              });
            }

            return AlertDialog(
              title: Text(
                initial == null
                    ? 'Ish elementi qo‘shish'
                    : 'Ish elementini tahrirlash',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: initial == null,
                      decoration: const InputDecoration(
                        labelText: 'Element nomi',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ish turi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<WorkElementType>(
                      segments: const [
                        ButtonSegment(
                          value: WorkElementType.productive,
                          label: Text('Samarali'),
                        ),
                        ButtonSegment(
                          value: WorkElementType.nonProductive,
                          label: Text('Samarasiz'),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (values) {
                        setDialogState(() => type = values.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Amal qilinishi kerak bo‘lgan talablar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bir yoki bir nechta talabni tanlash mumkin.',
                    ),
                    const SizedBox(height: 6),
                    ...WorkRequirement.values
                        .where((value) => value != WorkRequirement.none)
                        .map(
                          (value) => CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: requirements.contains(value),
                            title: Text(_requirementLabel(value)),
                            onChanged: (_) => toggleRequirement(value),
                          ),
                        ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: noRequirementSelected,
                      title: const Text('Hech narsa'),
                      onChanged: (_) {
                        setDialogState(() => requirements.clear());
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tekshirish usuli',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kerak bo‘lsa bir nechta usulni tanlang.',
                    ),
                    const SizedBox(height: 6),
                    ...VerificationMethod.values.map(
                      (value) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: verificationMethods.contains(value),
                        title: Text(_verificationLabel(value)),
                        onChanged: (_) {
                          setDialogState(() {
                            if (verificationMethods.contains(value)) {
                              verificationMethods.remove(value);
                            } else {
                              verificationMethods.add(value);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: basisController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Asos / standart / hujjat',
                        hintText:
                            'Masalan: CVIS 009-2025; Std-275537:2025; QCOS 2344433:2025',
                        border: OutlineInputBorder(),
                        helperText:
                            'Bir nechta asosni ; bilan ajratib yozish mumkin.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Bekor qilish'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(
                      dialogContext,
                      _ElementDraft(
                        name: name,
                        type: type,
                        requirements: requirements.toList(),
                        verificationMethods: verificationMethods.toList(),
                        basis: basisController.text.trim(),
                      ),
                    );
                  },
                  child: Text(initial == null ? 'Qo‘shish' : 'Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    basisController.dispose();
    return result;
  }

  Future<void> _addElement() async {
    final draft = await _showElementDialog();
    if (draft == null) return;

    setState(() {
      _elements.add(
        WorkElement(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: draft.name,
          type: draft.type,
          requirements: List.unmodifiable(draft.requirements),
          verificationMethods: List.unmodifiable(draft.verificationMethods),
          basis: draft.basis,
        ),
      );
    });
    _queueSave();
  }

  Future<void> _editElement(int index) async {
    final element = _elements[index];
    final draft = await _showElementDialog(initial: element);
    if (draft == null) return;

    setState(() {
      _elements[index] = element.copyWith(
        name: draft.name,
        type: draft.type,
        requirements: List.unmodifiable(draft.requirements),
        verificationMethods: List.unmodifiable(draft.verificationMethods),
        basis: draft.basis,
      );
    });
    _queueSave();
  }

  void _deleteElement(int index) {
    if (_runningCycle) return;
    setState(() => _elements.removeAt(index));
    _queueSave();
  }

  void _moveElement(int index, int direction) {
    if (_runningCycle) return;
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _elements.length) return;

    setState(() {
      final element = _elements.removeAt(index);
      _elements.insert(newIndex, element);
    });
    _queueSave();
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
      body: Stack(
        children: [
          ListView(
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
            onSelectionChanged: (v) {
              setState(() => _workType = v.first);
              _queueSave();
            },
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
                final index = e.key;
                final element = e.value;
                final elementSummary = elementSummaries[index];

                return Card(
                  key: ValueKey(element.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(element.name),
                      subtitle: _elementDetails(element, elementSummary, fmt),
                      isThreeLine: true,
                      trailing: SizedBox(
                        width: 126,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Yuqoriga',
                              onPressed: _runningCycle || index == 0
                                  ? null
                                  : () => _moveElement(index, -1),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Pastga',
                              onPressed: _runningCycle ||
                                      index == _elements.length - 1
                                  ? null
                                  : () => _moveElement(index, 1),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _editElement(index);
                                if (value == 'delete') _deleteElement(index);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Tahrirlash'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('O‘chirish'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
          ),
          if (_loadingSession)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _elementDetails(
    WorkElement element,
    ElementSummary summary,
    String Function(Duration?) fmt,
  ) {
    final requirementText = element.requirements.isEmpty
        ? 'Talab: Hech narsa'
        : 'Talab: ${element.requirements.map(_requirementLabel).join(', ')}';
    final verificationText = element.verificationMethods.isEmpty
        ? 'Tekshirish: —'
        : 'Tekshirish: ${element.verificationMethods.map(_verificationLabel).join(', ')}';
    final basisText = element.basis.isEmpty ? '' : ' • Asos: ${element.basis}';

    return Text(
      '${element.type == WorkElementType.productive ? 'Samarali ish' : 'Samarasiz ish'}'
      ' • ${summary.count} ta o‘lchov'
      ' • O‘rtacha: ${fmt(summary.average)}\n'
      '$requirementText • $verificationText$basisText',
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _requirementLabel(WorkRequirement value) {
    switch (value) {
      case WorkRequirement.safety:
        return 'Xavfsizlik';
      case WorkRequirement.quality:
        return 'Sifat';
      case WorkRequirement.sequence:
        return 'Ketma-ketlik';
      case WorkRequirement.stepSequence:
        return 'Qadam ichidagi ketma-ketlik';
      case WorkRequirement.qcos:
        return 'QCOS';
      case WorkRequirement.none:
        return 'Hech narsa';
    }
  }

  String _verificationLabel(VerificationMethod value) {
    switch (value) {
      case VerificationMethod.visual:
        return 'Ko‘rish';
      case VerificationMethod.auditory:
        return 'Eshitish';
      case VerificationMethod.touch:
        return 'Teginish';
      case VerificationMethod.measurement:
        return 'O‘lchash';
    }
  }
}

class _ElementDraft {
  const _ElementDraft({
    required this.name,
    required this.type,
    required this.requirements,
    required this.verificationMethods,
    required this.basis,
  });

  final String name;
  final WorkElementType type;
  final List<WorkRequirement> requirements;
  final List<VerificationMethod> verificationMethods;
  final String basis;
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

// This sentinel is used only to make the "none" choice explicit in the UI.
// It is never stored in a WorkElement.
extension WorkRequirementNone on WorkRequirement {
  static const WorkRequirement none = _WorkRequirementNone.value;
}

enum _WorkRequirementNone { value }
