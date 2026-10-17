import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(preferences: prefs);
    await storageService.init();
  });

  group('LocalStorageService Unit Tests', () {
    test('Throws StateError if accessed before initialization without prefs', () {
      final uninitService = LocalStorageService();
      expect(() => uninitService.getString('any_key'), throwsStateError);
    });

    test('setString and getString persists value correctly', () async {
      await storageService.setString('username', 'Mudasir Ali');
      expect(storageService.getString('username'), equals('Mudasir Ali'));
      expect(storageService.getString('non_existent'), isNull);
    });

    test('setStringList and getStringList persists lists correctly', () async {
      final symbols = ['AAPL', 'MSFT', 'NVDA'];
      await storageService.setStringList('watchlist_tech', symbols);
      expect(storageService.getStringList('watchlist_tech'), equals(symbols));
    });

    test('setJson and getJson handles valid and corrupted JSON maps', () async {
      final map = {'theme': 'dark', 'version': 1, 'active': true};
      await storageService.setJson('app_config', map);
      expect(storageService.getJson('app_config'), equals(map));

      // Test corrupted string stored directly
      await storageService.setString('corrupt_json', '{not a valid json}');
      expect(storageService.getJson('corrupt_json'), isNull);
    });

    test('setJsonList and getJsonList handles list of maps', () async {
      final list = [
        {'id': 'w1', 'name': 'Tech', 'count': 5},
        {'id': 'w2', 'name': 'Crypto', 'count': 2},
      ];
      await storageService.setJsonList('watchlists', list);
      final retrieved = storageService.getJsonList('watchlists');
      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(2));
      expect(retrieved.first['name'], equals('Tech'));

      // Test corrupted json list
      await storageService.setString('corrupt_list', 'not a json list');
      expect(storageService.getJsonList('corrupt_list'), isNull);
    });

    test('remove and clear behaves properly', () async {
      await storageService.setString('k1', 'v1');
      await storageService.setString('k2', 'v2');
      expect(storageService.getString('k1'), equals('v1'));

      await storageService.remove('k1');
      expect(storageService.getString('k1'), isNull);
      expect(storageService.getString('k2'), equals('v2'));

      await storageService.clear();
      expect(storageService.getString('k2'), isNull);
    });
  });
}
