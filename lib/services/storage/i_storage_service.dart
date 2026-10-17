import 'dart:async';

/// Abstract storage service contract defining key-value and structured JSON persistence.
abstract class IStorageService {
  /// Initializes the underlying storage provider.
  Future<void> init();

  /// Persists a string value for the given [key].
  Future<bool> setString(String key, String value);

  /// Retrieves a string value for the given [key], or null if absent.
  String? getString(String key);

  /// Persists a list of strings for the given [key].
  Future<bool> setStringList(String key, List<String> value);

  /// Retrieves a list of strings for the given [key], or null if absent.
  List<String>? getStringList(String key);

  /// Persists a structured JSON map for the given [key].
  Future<bool> setJson(String key, Map<String, dynamic> json);

  /// Retrieves a structured JSON map for the given [key], or null if absent or invalid.
  Map<String, dynamic>? getJson(String key);

  /// Persists a list of structured JSON maps for the given [key].
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> list);

  /// Retrieves a list of structured JSON maps for the given [key], or null if absent or invalid.
  List<Map<String, dynamic>>? getJsonList(String key);

  /// Removes the stored item associated with [key].
  Future<bool> remove(String key);

  /// Clears all keys stored by this application.
  Future<bool> clear();
}
