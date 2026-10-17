import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_storage_service.dart';

/// Concrete persistent storage implementation backed by [SharedPreferences].
class LocalStorageService implements IStorageService {
  LocalStorageService({SharedPreferences? preferences}) : _prefs = preferences;

  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _requirePrefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'LocalStorageService has not been initialized. Call init() before accessing storage.',
      );
    }
    return prefs;
  }

  @override
  Future<bool> setString(String key, String value) {
    return _requirePrefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _requirePrefs.getString(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) {
    return _requirePrefs.setStringList(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    return _requirePrefs.getStringList(key);
  }

  @override
  Future<bool> setJson(String key, Map<String, dynamic> json) {
    final encoded = jsonEncode(json);
    return _requirePrefs.setString(key, encoded);
  }

  @override
  Map<String, dynamic>? getJson(String key) {
    final raw = _requirePrefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> list) {
    final encoded = jsonEncode(list);
    return _requirePrefs.setString(key, encoded);
  }

  @override
  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _requirePrefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> remove(String key) {
    return _requirePrefs.remove(key);
  }

  @override
  Future<bool> clear() {
    return _requirePrefs.clear();
  }
}
