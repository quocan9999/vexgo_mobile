import 'dart:convert';
import 'package:flutter/services.dart';

class JsonLoader {
  JsonLoader._();

  /// Load a JSON file from the asset path and decode it.
  static Future<dynamic> loadJson(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString);
    } catch (e) {
      throw Exception('Không thể tải mock data từ file $assetPath: $e');
    }
  }

  /// Load a list of JSON objects from the asset path.
  static Future<List<Map<String, dynamic>>> loadJsonList(String assetPath) async {
    final dynamic data = await loadJson(assetPath);
    if (data is List) {
      return data.map((item) => item as Map<String, dynamic>).toList();
    }
    throw Exception('Dữ liệu tại $assetPath không phải là danh sách (List)');
  }

  /// Load a single JSON map from the asset path.
  static Future<Map<String, dynamic>> loadJsonMap(String assetPath) async {
    final dynamic data = await loadJson(assetPath);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Dữ liệu tại $assetPath không phải là đối tượng (Map)');
  }
}
