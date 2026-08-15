import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/time_study_models.dart';

class TimeStudyPage extends StatefulWidget {
  const TimeStudyPage({super.key});

  @override
  State<TimeStudyPage> createState() => _TimeStudyPageState();
}

class _TimeStudyPageState extends State<TimeStudyPage> {
  final _nameController = TextEditingController();
  WorkType _workType = WorkType.cyclic;
  final List<WorkElement> _elements = [];
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    setState(() {});
  }

  void _resetTimer() {
    _timer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {});
  }

  void _addElement() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ish elementi qo‘shish'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Element nomi',
              hintText: 'Masalan: detalni olish',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  return;
                }

                setState(() {
                  _elements.add(
                    WorkElement(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      type: WorkElementType.productive,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Qo‘shish'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (duration.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '${duration.inHours.toString().padLeft(2, '0')}:$minutes:$seconds.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Study'),
      ),
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
            'Avval sessiya turini va ish elementlarini belgilang. Keyingi bosqichlarda '
            'cycle yozuvlari, rating, allowance va Standard Time hisoblari qo‘shiladi.',
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
            onSelectionChanged: (value) {
              setState(() => _workType = value.first);
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _format(elapsed),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _stopwatch.isRunning
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _stopwatch.isRunning ? 'Pause' : 'Start',
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ish elementlari (${_elements.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addElement,
                icon: const Icon(Icons.add),
                label: const Text('Qo‘shish'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_elements.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Hali element qo‘shilmagan. Xronometrajni aniq tahlil qilish '
                  'uchun ishni o‘lchanadigan elementlarga ajrating.',
                ),
              ),
            )
          else
            ..._elements.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(entry.value.name),
                  subtitle: Text(
                    entry.value.type == WorkElementType.productive
                        ? 'Samarali ish'
                        : 'Samarasiz ish',
                  ),
                  trailing: IconButton(
                    tooltip: 'O‘chirish',
                    onPressed: () {
                      setState(() => _elements.removeAt(entry.key));
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
