import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    this.parentId = '',
    this.code = '',
  });

  final String id;
  final String name;
  final String type;
  final String parentId;
  final String code;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'parentId': parentId,
        'code': code,
      };

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        parentId: json['parentId'] as String? ?? '',
        code: json['code'] as String? ?? '',
      );
}

class CatalogStorage {
  static const key = 'catalog_v1';

  Future<List<CatalogItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(CatalogItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<CatalogItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
