import 'package:flutter/material.dart';

import '../data/catalog_models.dart';
import '../../../core/data/app_history.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _storage = CatalogStorage();
  final _name = TextEditingController();
  final _code = TextEditingController();
  String _type = 'Product';
  String _parent = '';
  List<CatalogItem> _items = [];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final v = await _storage.load(); if (mounted) setState(() => _items = v); }
  Future<void> _add() async {
    if (_name.text.trim().isEmpty) return;
    final item = CatalogItem(id: DateTime.now().microsecondsSinceEpoch.toString(), name: _name.text.trim(), code: _code.text.trim(), type: _type, parentId: _parent);
    final next = [..._items, item];
    await _storage.save(next);
    await AppHistoryStorage().add(HistoryEntry(module: 'Catalog', title: item.name, subtitle: item.type));
    _name.clear(); _code.clear();
    if (mounted) { setState(() => _items = next); Navigator.of(context).pop(); }
  }

  @override
  void dispose() { _name.dispose(); _code.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final types = ['Product', 'Model', 'Process', 'Operation', 'Worker / Position', 'Line / Area'];
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20), child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(value: _type, items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _type = v ?? _type), decoration: const InputDecoration(labelText: 'Type')), TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code')), const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: _add, child: const Text('Saqlash')))])), label: const Text('Qo‘shish'), icon: const Icon(Icons.add)),
      body: _items.isEmpty ? const Center(child: Text('Catalog bo‘sh. Product → Model → Process → Operation kabi obyektlarni qo‘shing.')) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length, itemBuilder: (_, i) { final e = _items[i]; return Card(child: ListTile(leading: const Icon(Icons.inventory_2_outlined), title: Text(e.name), subtitle: Text('${e.type}${e.code.isEmpty ? '' : ' • ${e.code}'}'), trailing: e.parentId.isEmpty ? null : Text(e.parentId)); }); }),
    );
  }
}
