import 'package:equatable/equatable.dart';
import '../../models/alert_model.dart';
import '../../models/instrument_model.dart';

abstract class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

/// Initializes alerts from repository
class AlertsInitialized extends AlertsEvent {
  const AlertsInitialized();
}

/// Creates a new price alert
class AlertCreated extends AlertsEvent {
  final AlertModel alert;

  const AlertCreated(this.alert);

  @override
  List<Object?> get props => [alert];
}

/// Deletes an existing alert
class AlertDeleted extends AlertsEvent {
  final String alertId;

  const AlertDeleted(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

/// Enables or disables an alert
class AlertToggled extends AlertsEvent {
  final String alertId;
  final bool enabled;

  const AlertToggled({
    required this.alertId,
    required this.enabled,
  });

  @override
  List<Object?> get props => [alertId, enabled];
}

/// Real-time market tick evaluated against active alerts
class AlertPriceTickEvaluated extends AlertsEvent {
  final InstrumentModel instrument;

  const AlertPriceTickEvaluated(this.instrument);

  @override
  List<Object?> get props => [instrument];
}

/// Clears recently triggered alert notification banner
class AlertNotificationDismissed extends AlertsEvent {
  final String alertId;

  const AlertNotificationDismissed(this.alertId);

  @override
  List<Object?> get props => [alertId];
}
