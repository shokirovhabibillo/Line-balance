import 'package:flutter/material.dart';

import '../../../core/data/app_history.dart';
import '../data/catalog_models.dart';

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
  final String _parent = '';
  List<CatalogItem> _items = [];

  static const _types = <String>[
    'Product',
    'Model',
    'Process',
    'Operation',
    'Worker / Position',
    'Line / Area',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.load();
    if (mounted) {
      setState(() => _items = items);
    }
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final item = CatalogItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      code: _code.text.trim(),
      type: _type,
      parentId: _parent,
    );
    final next = [..._items, item];

    await _storage.save(next);
    await AppHistoryStorage().add(
      HistoryEntry(
        module: 'Catalog',
        title: item.name,
        subtitle: item.type,
        savedAt: DateTime.now(),
      ),
    );

    _name.clear();
    _code.clear();
    if (mounted) {
      setState(() => _items = next);
      Navigator.of(context).pop();
    }
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: _types
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _add,
                  child: const Text('Saqlash'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        label: const Text('Qo‘shish'),
        icon: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Catalog bo‘sh. Product → Model → Process → Operation kabi obyektlarni qo‘shing.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.type}${item.code.isEmpty ? '' : ' • ${item.code}'}',
                    ),
                    trailing: item.parentId.isEmpty
                        ? null
                        : Text(item.parentId),
                  ),
                );
              },
            ),
    );
  }
}
