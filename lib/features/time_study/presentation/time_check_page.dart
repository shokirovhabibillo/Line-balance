import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/time_study_models.dart';

class TimeCheckResult {
  const TimeCheckResult({required this.cycle, required this.elements});

  final Duration cycle;
  final List<ElementRecord> elements;
}

class TimeCheckPage extends StatefulWidget {
  const TimeCheckPage({
    super.key,
    required this.elements,
    required this.cycleNumber,
  });

  final List<WorkElement> elements;
  final int cycleNumber;

  @override
  State<TimeCheckPage> createState() => _TimeCheckPageState();
}

class _TimeCheckPageState extends State<TimeCheckPage> {
  Timer? _ticker;
  final _cycleWatch = Stopwatch();
  final _segmentWatch = Stopwatch();
  final _records = <ElementRecord>[];
  int _index = 0;
  bool _runningCycle = false;
  bool _runningSegment = false;
  DateTime? _lastMark;

  WorkElement? get _current => _index < widget.elements.length ? widget.elements[_index] : null;
  bool get _allMeasured => _index >= widget.elements.length;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCycle() {
    if (_runningCycle || widget.elements.isEmpty) return;
    _cycleWatch..reset()..start();
    _runningCycle = true;
    _lastMark = DateTime.now();
    _startTicker();
    setState(() {});
  }

  void _startElement() {
    final element = _current;
    if (!_runningCycle || _runningSegment || element == null || element.measurementMode != MeasurementMode.startFinish) return;
    _segmentWatch..reset()..start();
    _runningSegment = true;
    setState(() {});
  }

  void _finishElement() {
    final element = _current;
    if (!_runningCycle || element == null) return;
    final now = DateTime.now();
    Duration duration;
    if (element.measurementMode == MeasurementMode.cycleLinkedFinishOnly) {
      final start = _lastMark ?? now;
      duration = now.difference(start);
    } else {
      if (!_runningSegment) return;
      _segmentWatch.stop();
      duration = _segmentWatch.elapsed;
    }
    if (duration <= Duration.zero) return;
    _records.add(ElementRecord(elementId: element.id, duration: duration, recordedAt: now));
    _lastMark = now;
    _runningSegment = false;
    _segmentWatch.reset();
    _index++;
    setState(() {});
  }

  void _finishCycle() {
    if (!_runningCycle || _runningSegment || !_allMeasured) return;
    _cycleWatch.stop();
    _ticker?.cancel();
    final result = TimeCheckResult(cycle: _cycleWatch.elapsed, elements: List.unmodifiable(_records));
    Navigator.of(context).pop(result);
  }

  void _reset() {
    _ticker?.cancel();
    _cycleWatch..stop()..reset();
    _segmentWatch..stop()..reset();
    _records.clear();
    _index = 0;
    _runningCycle = false;
    _runningSegment = false;
    _lastMark = null;
    setState(() {});
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '${d.inHours.toString().padLeft(2, '0')}:$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final cycleText = _format(_cycleWatch.elapsed);
    final elementText = _format(_segmentWatch.elapsed);
    return Scaffold(
      appBar: AppBar(title: Text('Time Check • Cycle #${widget.cycleNumber}')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(cycleText, key: const Key('time_check_cycle_timer'), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(current == null ? 'Cycle tugadi' : current.name, style: Theme.of(context).textTheme.titleMedium),
                      if (_runningSegment) ...[
                        const SizedBox(height: 4),
                        Text('Element: $elementText'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.elements.length,
                itemBuilder: (context, index) {
                  final e = widget.elements[index];
                  final record = index < _records.length ? _records[index] : null;
                  final isCurrent = index == _index;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: record != null ? const Icon(Icons.check) : Text('${index + 1}')),
                      title: Text(e.name),
                      subtitle: Text(
                        record != null
                            ? 'O‘lchangan • ${_format(record.duration)}'
                            : isCurrent
                                ? e.measurementMode == MeasurementMode.cycleLinkedFinishOnly
                                    ? 'O‘lchanmoqda • Cycle-linked / Finish-only'
                                    : 'O‘lchanmoqda • Start + Finish'
                                : 'Navbatdagi jarayon',
                      ),
                      trailing: isCurrent ? const Icon(Icons.radio_button_checked) : null,
                    ),
                  );
                },
              ),
            ),
            Material(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _runningCycle ? null : _startCycle,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('START CYCLE'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _runningCycle ? _reset : null,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('RESET'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _runningCycle && !_runningSegment && current?.measurementMode == MeasurementMode.startFinish ? _startElement : null,
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('START ELEMENT'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _runningCycle && current != null && (current.measurementMode == MeasurementMode.cycleLinkedFinishOnly || _runningSegment) ? _finishElement : null,
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('FINISH ELEMENT'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _runningCycle && !_runningSegment && _allMeasured ? _finishCycle : null,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('FINISH CYCLE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
