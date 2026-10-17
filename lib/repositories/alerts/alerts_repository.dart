import '../../models/alert_model.dart';
import '../../services/storage/i_storage_service.dart';
import 'i_alerts_repository.dart';

/// Concrete Alerts Repository backed by [IStorageService]
class AlertsRepository implements IAlertsRepository {
  static const String keyAlerts = 'trading_price_alerts';

  final IStorageService storage;

  AlertsRepository({required this.storage});

  @override
  Future<List<AlertModel>> getAlerts() async {
    final rawList = storage.getJsonList(keyAlerts);
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    return rawList.map((e) => AlertModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveAlert(AlertModel alert) async {
    final current = await getAlerts();
    final updated = [alert, ...current.where((a) => a.id != alert.id)];
    final jsonList = updated.map((a) => a.toJson()).toList();
    await storage.setJsonList(keyAlerts, jsonList);
  }

  @override
  Future<void> updateAlert(AlertModel alert) async {
    final current = await getAlerts();
    final updated = current.map((a) => a.id == alert.id ? alert : a).toList();
    final jsonList = updated.map((a) => a.toJson()).toList();
    await storage.setJsonList(keyAlerts, jsonList);
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    final current = await getAlerts();
    final updated = current.where((a) => a.id != alertId).toList();
    final jsonList = updated.map((a) => a.toJson()).toList();
    await storage.setJsonList(keyAlerts, jsonList);
  }
}
