import '../../models/alert_model.dart';

/// Interface defining contract for Price Alerts storage and persistence
abstract class IAlertsRepository {
  Future<List<AlertModel>> getAlerts();
  Future<void> saveAlert(AlertModel alert);
  Future<void> updateAlert(AlertModel alert);
  Future<void> deleteAlert(String alertId);
}
