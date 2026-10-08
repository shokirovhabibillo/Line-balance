import 'package:flutter/material.dart';

import '../data/four_m_models.dart';

class FourMPage extends StatefulWidget {
  const FourMPage({super.key});

  @override
  State<FourMPage> createState() => _FourMPageState();
}

class _FourMPageState extends State<FourMPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _employees = <Employee>[
    Employee(id: 'E-001', name: 'Worker A', position: 'Operator', brigade: 'A', station: '01RH', shift: '1', jitLevel: 3, flexibility: {'OP-01': 3, 'OP-02': 3, 'OP-03': 2, 'OP-04': 1}),
    Employee(id: 'E-002', name: 'Worker B', position: 'Operator', brigade: 'A', station: '02RH', shift: '1', jitLevel: 2, flexibility: {'OP-01': 2, 'OP-02': 3, 'OP-03': 1, 'OP-04': 0}),
  ];
  final _machines = const [
    MachineInfo(name: 'Torque Tool 01', station: '01RH', status: 'Ready', cycleTimeMs: 4200),
    MachineInfo(name: 'Scanner 01', station: '01RH', status: 'Ready', cycleTimeMs: 1800),
  ];
  final _materials = const [
    MaterialInfo(name: 'Option List', partNumber: 'OPT-001', requiredQty: 1, availableQty: 1),
    MaterialInfo(name: 'Body', partNumber: 'BODY-001', requiredQty: 1, availableQty: 1),
  ];
  final _methods = const [
    MethodInfo(operation: 'Scan and compare', standard: 'SOS/JES', requirement: 'Sequence + quality', verification: 'Visual'),
    MethodInfo(operation: 'Attach option list', standard: 'Standard Work', requirement: 'Correct body number', verification: 'Visual'),
  ];
  final _workstations = const [
    Workstation4M(station: '01RH', man: 'Worker A', machine: 'Scanner 01', material: 'Option List', method: 'Scan and compare'),
    Workstation4M(station: '02RH', man: 'Worker B', machine: 'Torque Tool 01', material: 'Body', method: 'Standard Work'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addEmployee() async {
    final name = TextEditingController();
    final position = TextEditingController();
    final brigade = TextEditingController();
    final station = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Employee qo‘shish'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Ism / ID')),
            TextField(controller: position, decoration: const InputDecoration(labelText: 'Lavozim')),
            TextField(controller: brigade, decoration: const InputDecoration(labelText: 'Brigada')),
            TextField(controller: station, decoration: const InputDecoration(labelText: 'Station')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(context, [name.text, position.text, brigade.text, station.text]), child: const Text('Saqlash')),
        ],
      ),
    );
    if (result == null || result.first.trim().isEmpty || !mounted) return;
    setState(() => _employees.add(Employee(
          id: 'E-${(_employees.length + 1).toString().padLeft(3, '0')}',
          name: result[0].trim(),
          position: result[1].trim(),
          brigade: result[2].trim(),
          station: result[3].trim(),
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('4M Foundation'),
        bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
          Tab(text: 'Man', icon: Icon(Icons.people_outline)),
          Tab(text: 'Machine', icon: Icon(Icons.precision_manufacturing_outlined)),
          Tab(text: 'Material', icon: Icon(Icons.inventory_2_outlined)),
          Tab(text: 'Method', icon: Icon(Icons.rule_outlined)),
          Tab(text: 'Workstation', icon: Icon(Icons.grid_view_outlined)),
        ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _manView(),
        _machineView(),
        _materialView(),
        _methodView(),
        _workstationView(),
      ]),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) => _tabs.index == 0
            ? FloatingActionButton.extended(onPressed: _addEmployee, icon: const Icon(Icons.person_add), label: const Text('Employee'))
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _manView() => ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(title: Text('Man / People'), subtitle: Text('Employee, JIT assessment, flexibility va attendance'))),
        ..._employees.map((e) => Card(child: ExpansionTile(
              key: Key('employee_${e.id}'),
              title: Text(e.name),
              subtitle: Text('${e.position} • Brigada ${e.brigade} • ${e.station}'),
              children: [
                ListTile(leading: const Icon(Icons.school_outlined), title: const Text('JIT assessment'), trailing: Text('${e.jitLevel}/3')),
                ListTile(leading: const Icon(Icons.hub_outlined), title: const Text('Flexibility'), subtitle: Text(e.flexibility.entries.map((x) => '${x.key}: ${x.value}').join('  '))),
                ListTile(leading: const Icon(Icons.event_available_outlined), title: const Text('Attendance'), trailing: Text(e.attendanceStatus)),
              ],
            ))),
        const SizedBox(height: 8),
        const Text('JIT assessment darajalari kompaniya standarti bilan belgilanadi; platforma qiymatni saqlaydi va taqqoslaydi.'),
      ]);

  Widget _machineView() => ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(title: Text('Machine'), subtitle: Text('Equipment, station, status va cycle time'))),
        ..._machines.map((m) => Card(child: ListTile(title: Text(m.name), subtitle: Text('${m.station} • CT ${m.cycleTimeMs} ms'), trailing: Chip(label: Text(m.status))))),
      ]);

  Widget _materialView() => ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(title: Text('Material'), subtitle: Text('Part number, talab, mavjudlik va shortage'))),
        ..._materials.map((m) => Card(child: ListTile(title: Text(m.name), subtitle: Text('${m.partNumber} • Required ${m.requiredQty} • Available ${m.availableQty}'), trailing: m.shortage > 0 ? Chip(label: Text('Shortage ${m.shortage}')) : const Chip(label: Text('OK'))))),
      ]);

  Widget _methodView() => ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(title: Text('Method'), subtitle: Text('Operation, standard, requirement va verification'))),
        ..._methods.map((m) => Card(child: ListTile(title: Text(m.operation), subtitle: Text('${m.standard} • ${m.requirement}'), trailing: Text(m.verification)))),
        const SizedBox(height: 8),
        const Card(child: ListTile(leading: Icon(Icons.error_outline), title: Text('Error Proofing / Agar'), subtitle: Text('Shart → Aniqlash → Harakat → Eskalatsiya → Line Stop'))),
      ]);

  Widget _workstationView() => ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(title: Text('Workstation 4M'), subtitle: Text('Bitta stationdagi Man + Machine + Material + Method'))),
        ..._workstations.map((w) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.station, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('Man: ${w.man}'),
              Text('Machine: ${w.machine}'),
              Text('Material: ${w.material}'),
              Text('Method: ${w.method}'),
            ])))),
        const SizedBox(height: 8),
        const Text('Keyingi bosqich: 4M holatini Time Study, Line Balance, Downtime va bottleneck risk bilan bog‘lash.'),
      ]);
}
