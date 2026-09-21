import 'dart:async';

import 'package:flutter/material.dart';

import '../application/time_study_calculator.dart';
import '../data/time_study_excel_exchange.dart';
import '../data/time_study_storage.dart';
import '../domain/time_study_models.dart';
import 'time_check_page.dart';
import 'time_study_history_page.dart';
import '../data/time_study_history_storage.dart';

class TimeStudyPage extends StatefulWidget {
  const TimeStudyPage({super.key});

  @override
  State<TimeStudyPage> createState() => _TimeStudyPageState();
}

class _TimeStudyPageState extends State<TimeStudyPage> {
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _section = TextEditingController();
  final _line = TextEditingController();
  final _station = TextEditingController();
  final _worker = TextEditingController();
  final _storage = const TimeStudyStorage();
  final _excel = TimeStudyExcelExchange();
  final _history = TimeStudyHistoryStorage();
  final _calculator = const TimeStudyCalculator();
  final _elements = <WorkElement>[];
  final _cycles = <CycleRecord>[];
  bool _loading = true;
  bool _busy = false;
  WorkType _workType = WorkType.cyclic;
  Future<void> _saveChain = Future<void>.value();

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _department, _section, _line, _station, _worker]) {
      c.addListener(_queueSave);
    }
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.load();
    if (!mounted) return;
    if (data != null) {
      _name.text = data.sessionName;
      _department.text = data.department;
      _section.text = data.section;
      _line.text = data.line;
      _station.text = data.station;
      _worker.text = data.worker;
      _workType = data.workType;
      _elements..clear()..addAll(data.elements);
      _cycles..clear()..addAll(data.cycles);
    }
    setState(() => _loading = false);
  }

  TimeStudySessionData _data() => TimeStudySessionData(
        sessionName: _name.text.trim(),
        workType: _workType,
        department: _department.text.trim(),
        section: _section.text.trim(),
        line: _line.text.trim(),
        station: _station.text.trim(),
        worker: _worker.text.trim(),
        elements: List.unmodifiable(_elements),
        cycles: List.unmodifiable(_cycles),
      );

  void _queueSave() {
    if (_loading) return;
    final data = _data();
    _saveChain = _saveChain.then((_) => _storage.save(data));
  }

  @override
  void dispose() {
    for (final c in [_name, _department, _section, _line, _station, _worker]) {
      c.removeListener(_queueSave);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _openTimeCheck() async {
    if (_elements.isEmpty) {
      _message('Avval kamida bitta ish elementini qo‘shing.');
      return;
    }
    final result = await Navigator.of(context).push<TimeCheckResult>(
      MaterialPageRoute(builder: (_) => TimeCheckPage(elements: List.unmodifiable(_elements), cycleNumber: _cycles.length + 1)),
    );
    if (result == null) return;
    setState(() {
      _cycles.add(CycleRecord(
        number: _cycles.length + 1,
        duration: result.cycle,
        recordedAt: DateTime.now(),
        elements: result.elements,
      ));
    });
    _queueSave();
    await _history.add(_data());
  }

  Future<void> _addElement() async {
    final draft = await _showElementDialog();
    if (draft == null) return;
    setState(() {
      _elements.add(WorkElement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: draft.name,
        type: draft.type,
        requirements: List.unmodifiable(draft.requirements),
        property: draft.property,
        verificationMethods: List.unmodifiable(draft.verificationMethods),
        basis: draft.basis,
        measurementMode: draft.measurementMode,
        selectedTime: draft.selectedTime,
      ));
    });
    _queueSave();
  }

  Future<void> _editElement(int index) async {
    final draft = await _showElementDialog(initial: _elements[index]);
    if (draft == null) return;
    final old = _elements[index];
    setState(() {
      _elements[index] = old.copyWith(
        name: draft.name,
        type: draft.type,
        requirements: List.unmodifiable(draft.requirements),
        property: draft.property,
        verificationMethods: List.unmodifiable(draft.verificationMethods),
        basis: draft.basis,
        measurementMode: draft.measurementMode,
        selectedTime: draft.selectedTime,
      );
    });
    _queueSave();
  }

  Future<void> _deleteElement(int index) async {
    if (_cycles.isNotEmpty) {
      _message('O‘lchov yozuvlari bor. Elementni o‘chirishdan oldin yangi session yarating yoki ma’lumotlarni eksport qiling.');
      return;
    }
    final ok = await _confirm('Elementni o‘chirish', '“${_elements[index].name}” elementini o‘chirishni tasdiqlaysizmi?');
    if (!ok) return;
    setState(() => _elements.removeAt(index));
    _queueSave();
  }

  Future<void> _deleteCycle(int index) async {
    final cycle = _cycles[index];
    final ok = await _confirm('Cycle yozuvini o‘chirish', 'Cycle #${cycle.number} yozuvini o‘chirishni tasdiqlaysizmi?');
    if (!ok) return;
    setState(() {
      _cycles.removeAt(index);
      for (var i = 0; i < _cycles.length; i++) {
        _cycles[i] = _cycles[i].copyWith(number: i + 1);
      }
    });
    _queueSave();
  }

  Future<void> _importExcel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final imported = await _excel.importSession();
      if (imported == null) {
        _message('Excel fayl import qilinmadi. Kutilgan “Session” va “Work Elements” varaqlarini tekshiring.');
      } else {
        setState(() {
          _name.text = imported.sessionName;
          _workType = imported.workType;
          _department.text = imported.department;
          _section.text = imported.section;
          _line.text = imported.line;
          _station.text = imported.station;
          _worker.text = imported.worker;
          _elements..clear()..addAll(imported.elements);
          _cycles..clear()..addAll(imported.cycles);
        });
        _queueSave();
        _message('Excel ma’lumotlari import qilindi.');
      }
    } catch (e) {
      _message('Import xatosi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportExcel({bool template = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = template
          ? await _excel.exportTemplate()
          : await _excel.exportSession(_data(), _calculator.summarizeElements(_cycles, _elements));
      _message(ok ? 'Excel fayl tayyor.' : 'Saqlash bekor qilindi.');
    } catch (e) {
      _message('Export xatosi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_ElementDraft?> _showElementDialog({WorkElement? initial}) async {
    final name = TextEditingController(text: initial?.name ?? '');
    final property = TextEditingController(text: initial?.property ?? '');
    final selectedTime = TextEditingController(text: initial?.selectedTime == null ? '' : (initial!.selectedTime!.inMicroseconds / 1000000).toStringAsFixed(3));
    final basis = TextEditingController(text: initial?.basis ?? '');
    var type = initial?.type ?? WorkElementType.productive;
    var mode = initial?.measurementMode ?? MeasurementMode.startFinish;
    final requirements = <WorkRequirement>{...?initial?.requirements};
    final verification = <VerificationMethod>{...?initial?.verificationMethods};
    final result = await showDialog<_ElementDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(initial == null ? 'Ish elementi qo‘shish' : 'Ish elementini tahrirlash'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(controller: name, autofocus: initial == null, decoration: const InputDecoration(labelText: 'Element nomi', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SegmentedButton<WorkElementType>(
                  segments: const [
                    ButtonSegment(value: WorkElementType.productive, label: Text('Samarali')),
                    ButtonSegment(value: WorkElementType.nonProductive, label: Text('Samarasiz')),
                  ],
                  selected: {type}, onSelectionChanged: (v) => setState(() => type = v.first),
                ),
                const SizedBox(height: 14),
                const Text('O‘lchash usuli', style: TextStyle(fontWeight: FontWeight.w700)),
                RadioGroup<MeasurementMode>(
                  groupValue: mode,
                  onChanged: (v) {
                    if (v != null) setState(() => mode = v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<MeasurementMode>(
                        value: MeasurementMode.startFinish,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start + Finish Element'),
                        subtitle: const Text('Element alohida boshlanadi va tugatiladi.'),
                      ),
                      RadioListTile<MeasurementMode>(
                        value: MeasurementMode.cycleLinkedFinishOnly,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cycle-linked / Finish-only'),
                        subtitle: const Text('Cycle uzluksiz ishlaydi; navbatdagi element Finish Element bilan kesib olinadi.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Amal qilinishi kerak bo‘lgan talablar', style: TextStyle(fontWeight: FontWeight.w700)),
                ...WorkRequirement.values.where((v) => v != WorkRequirement.none).map((v) => CheckboxListTile(
                  dense: true, contentPadding: EdgeInsets.zero, value: requirements.contains(v), title: Text(_requirementLabel(v)),
                  onChanged: (_) => setState(() => requirements.contains(v) ? requirements.remove(v) : requirements.add(v)),
                )),
                const SizedBox(height: 8),
                TextField(controller: property, decoration: const InputDecoration(labelText: 'Xususiyati', hintText: 'Masalan: 4 Nm ± 0.5 Nm', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: selectedTime, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Tanlangan vaqt (s)', hintText: 'Ixtiyoriy: statistik tahlildan keyin muhandis tanlaydi', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text('Tekshirish usuli', style: TextStyle(fontWeight: FontWeight.w700)),
                ...VerificationMethod.values.map((v) => CheckboxListTile(
                  dense: true, contentPadding: EdgeInsets.zero, value: verification.contains(v), title: Text(_verificationLabel(v)),
                  onChanged: (_) => setState(() => verification.contains(v) ? verification.remove(v) : verification.add(v)),
                )),
                TextField(controller: basis, decoration: const InputDecoration(labelText: 'Asos / standart / hujjat', border: OutlineInputBorder())),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Bekor qilish')),
            FilledButton(onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, _ElementDraft(
                name: name.text.trim(), type: type, requirements: requirements.toList(), property: property.text.trim(),
                verificationMethods: verification.toList(), basis: basis.text.trim(), measurementMode: mode,
                selectedTime: double.tryParse(selectedTime.text.trim()) == null ? null : Duration(microseconds: (double.parse(selectedTime.text.trim()) * 1000000).round()),
              ));
            }, child: Text(initial == null ? 'Qo‘shish' : 'Saqlash')),
          ],
        ),
      ),
    );
    name.dispose(); property.dispose(); basis.dispose(); selectedTime.dispose();
    return result;
  }

  Future<bool> _confirm(String title, String text) async {
    return await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: Text(text),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qilish')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('O‘chirish'))],
    )) ?? false;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _fmt(Duration? d) => d == null ? '—' : '${d.inMilliseconds / 1000}s';

  String _requirementLabel(WorkRequirement v) => switch (v) {
        WorkRequirement.safety => 'Xavfsizlik', WorkRequirement.quality => 'Sifat', WorkRequirement.sequence => 'Ketma-ketlik',
        WorkRequirement.stepSequence => 'Qadam ichidagi ketma-ketlik', WorkRequirement.qcos => 'QCOS', WorkRequirement.none => 'Hech narsa',
      };

  String _verificationLabel(VerificationMethod v) => switch (v) {
        VerificationMethod.visual => 'Ko‘rish', VerificationMethod.auditory => 'Eshitish', VerificationMethod.touch => 'Teginish', VerificationMethod.measurement => 'O‘lchash',
      };

  @override
  Widget build(BuildContext context) {
    final summary = _calculator.summarize(_cycles);
    final elementSummaries = _calculator.summarizeElements(_cycles, _elements);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Study V2'),
        actions: [
          IconButton(tooltip: 'History', icon: const Icon(Icons.history), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimeStudyHistoryPage()))),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'import') _importExcel(); if (v == 'export') _exportExcel(); if (v == 'template') _exportExcel(template: true); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'import', child: Text('Excel import')),
              PopupMenuItem(value: 'export', child: Text('Excel export')),
              PopupMenuItem(value: 'template', child: Text('Excel namuna')), 
            ],
          ),
        ],
      ),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.all(20), children: [
          Text('Xronometraj sessiyasi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Avval ishni sozlang, keyin alohida ergonomik Time Check oynasida o‘lchang.'),
          const SizedBox(height: 20),
          _field(_name, 'Sessiya nomi', 'Masalan: ST-03 yig‘ish jarayoni'),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _field(_department, 'Ishlab chiqarish boshqarmasi', 'Ixtiyoriy')), const SizedBox(width: 10), Expanded(child: _field(_section, 'Uchastka / sex', 'Ixtiyoriy'))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _field(_line, 'Liniya', 'Ixtiyoriy')), const SizedBox(width: 10), Expanded(child: _field(_station, 'Sektor / station', 'Ixtiyoriy'))]),
          const SizedBox(height: 12),
          _field(_worker, 'Xodim / operator', 'Ixtiyoriy'),
          const SizedBox(height: 14),
          SegmentedButton<WorkType>(segments: const [ButtonSegment(value: WorkType.cyclic, label: Text('Siklik'), icon: Icon(Icons.repeat)), ButtonSegment(value: WorkType.nonCyclic, label: Text('Nosiklik'), icon: Icon(Icons.shuffle))], selected: {_workType}, onSelectionChanged: (v) { setState(() => _workType = v.first); _queueSave(); }),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: Text('Ish elementlari (${_elements.length})', key: const Key('work_elements_header'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))), FilledButton.tonalIcon(onPressed: _addElement, icon: const Icon(Icons.add), label: const Text('Qo‘shish'))]),
          const SizedBox(height: 8),
          if (_elements.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Xronometraj qilinadigan ishlarni ketma-ket qo‘shing. Har bir element uchun Xususiyati va o‘lchash usulini belgilang.'))),
          ..._elements.asMap().entries.map((entry) {
            final index = entry.key; final e = entry.value; final s = elementSummaries[index];
            return Card(child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')), title: Text(e.name),
              subtitle: Text('${e.type == WorkElementType.productive ? 'Samarali' : 'Samarasiz'} • ${e.measurementMode == MeasurementMode.startFinish ? 'Start + Finish' : 'Cycle-linked / Finish-only'}\nTalab: ${e.requirements.isEmpty ? '—' : e.requirements.map(_requirementLabel).join(', ')} • Xususiyati: ${e.property.isEmpty ? '—' : e.property}\nO‘lchov: ${s.validCount} • O‘rtacha: ${_fmt(s.average)}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _editElement(index); if (v == 'delete') _deleteElement(index); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Tahrirlash')), PopupMenuItem(value: 'delete', child: Text('O‘chirish'))]),
            ));
          }),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _elements.isEmpty ? null : _openTimeCheck, icon: const Icon(Icons.timer_outlined), label: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('TIME CHECK — o‘lchashni boshlash'))),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Wrap(spacing: 18, runSpacing: 14, children: [
            _Metric('Kuzatuv', '${summary.observedCount}'), _Metric('Valid', '${summary.validCount}'), _Metric('Excluded', '${summary.excludedCount}'), _Metric('Average', _fmt(summary.average)), _Metric('Median', _fmt(summary.median)), _Metric('Mode', _fmt(summary.mode)), _Metric('Min', _fmt(summary.minimum)), _Metric('Max', _fmt(summary.maximum)), _Metric('Range', _fmt(summary.range)),
          ]))),
          const SizedBox(height: 20),
          Text('Cycle yozuvlari (${_cycles.length})', key: const Key('cycle_records_header'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_cycles.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Hali cycle yozilmagan. Time Check oynasidan o‘lchashni boshlang.'))),
          ..._cycles.asMap().entries.map((entry) {
            final index = entry.key; final c = entry.value;
            return Card(child: ExpansionTile(
              leading: CircleAvatar(child: Text('${c.number}')), title: Text(_fmt(c.duration)), subtitle: Text('${c.elements.length} ta element • ${c.excluded ? 'Excluded' : 'Valid'}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Cycle o‘chirish', onPressed: () => _deleteCycle(index)),
              children: c.elements.map((r) => ListTile(dense: true, title: Text(_elementName(r.elementId)), subtitle: r.excluded ? Text('Excluded: ${r.exclusionReason}') : null, trailing: Text(_fmt(r.duration)))).toList(),
            ));
          }),
          const SizedBox(height: 80),
        ]),
        if (_loading || _busy) const Positioned.fill(child: ColoredBox(color: Color(0x66FFFFFF), child: Center(child: CircularProgressIndicator()))),
      ]),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint) => TextField(controller: controller, decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()));

  String _elementName(String id) {
    for (final e in _elements) { if (e.id == id) return e.name; }
    return 'Noma’lum element';
  }
}

class _ElementDraft {
  const _ElementDraft({required this.name, required this.type, required this.requirements, required this.property, required this.verificationMethods, required this.basis, required this.measurementMode, required this.selectedTime});
  final String name; final WorkElementType type; final List<WorkRequirement> requirements; final String property; final List<VerificationMethod> verificationMethods; final String basis; final MeasurementMode measurementMode; final Duration? selectedTime;
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label; final String value;
  @override Widget build(BuildContext context) => SizedBox(width: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 3), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))]));
}
