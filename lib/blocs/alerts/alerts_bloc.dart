import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/alert_model.dart';
import '../../repositories/alerts/i_alerts_repository.dart';
import 'alerts_event.dart';
import 'alerts_state.dart';

/// BLoC managing Price Alerts lifecycle, persistence, and real-time tick condition evaluation
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final IAlertsRepository repository;

  AlertsBloc({required this.repository}) : super(const AlertsInitial()) {
    on<AlertsInitialized>(_onAlertsInitialized);
    on<AlertCreated>(_onAlertCreated);
    on<AlertDeleted>(_onAlertDeleted);
    on<AlertToggled>(_onAlertToggled);
    on<AlertPriceTickEvaluated>(_onAlertPriceTickEvaluated);
    on<AlertNotificationDismissed>(_onAlertNotificationDismissed);
  }

  Future<void> _onAlertsInitialized(
    AlertsInitialized event,
    Emitter<AlertsState> emit,
  ) async {
    emit(const AlertsLoading());
    try {
      final alerts = await repository.getAlerts();
      emit(AlertsLoaded(alerts: alerts));
    } catch (e) {
      emit(AlertsActionFailure(errorMessage: 'Failed to load alerts: $e'));
    }
  }

  Future<void> _onAlertCreated(
    AlertCreated event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    try {
      await repository.saveAlert(event.alert);
      final updated = [event.alert, ...current.alerts.where((a) => a.id != event.alert.id)];
      emit(current.copyWith(
        alerts: updated,
        message:
            'Price alert set for ${event.alert.symbol} at \$${event.alert.targetPrice.toStringAsFixed(2)}',
      ));
    } catch (e) {
      emit(AlertsActionFailure(
        errorMessage: 'Failed to create alert: $e',
        previousState: current,
      ));
      emit(current);
    }
  }

  Future<void> _onAlertDeleted(
    AlertDeleted event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    try {
      await repository.deleteAlert(event.alertId);
      final updated = current.alerts.where((a) => a.id != event.alertId).toList();
      emit(current.copyWith(
        alerts: updated,
        message: 'Alert deleted',
      ));
    } catch (e) {
      emit(AlertsActionFailure(
        errorMessage: 'Failed to delete alert: $e',
        previousState: current,
      ));
      emit(current);
    }
  }

  Future<void> _onAlertToggled(
    AlertToggled event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    final alert = current.alerts.cast<AlertModel?>().firstWhere(
          (a) => a?.id == event.alertId,
          orElse: () => null,
        );

    if (alert == null) return;

    final updatedAlert = alert.copyWith(
      status: event.enabled ? AlertStatus.active : AlertStatus.disabled,
    );

    try {
      await repository.updateAlert(updatedAlert);
      final updated = current.alerts
          .map((a) => a.id == updatedAlert.id ? updatedAlert : a)
          .toList();
      emit(current.copyWith(
        alerts: updated,
        message: event.enabled
            ? 'Alert enabled for ${alert.symbol}'
            : 'Alert paused for ${alert.symbol}',
      ));
    } catch (e) {
      emit(AlertsActionFailure(
        errorMessage: 'Failed to update alert: $e',
        previousState: current,
      ));
      emit(current);
    }
  }

  Future<void> _onAlertPriceTickEvaluated(
    AlertPriceTickEvaluated event,
    Emitter<AlertsState> emit,
  ) async {
    final current = state;
    if (current is! AlertsLoaded) return;

    final tick = event.instrument;
    final now = DateTime.now();

    List<AlertModel> updatedAlerts = List.from(current.alerts);
    AlertModel? triggeredAlert;

    for (int i = 0; i < updatedAlerts.length; i++) {
      final alert = updatedAlerts[i];
      if (alert.isActive &&
          alert.symbol.toUpperCase() == tick.symbol.toUpperCase()) {
        if (alert.shouldTrigger(tick.price)) {
          final triggered = alert.copyWith(
            status: AlertStatus.triggered,
            triggeredAt: now,
            triggeredPrice: tick.price,
          );
          updatedAlerts[i] = triggered;
          triggeredAlert = triggered;
          await repository.updateAlert(triggered);
        }
      }
    }

    if (triggeredAlert != null) {
      emit(current.copyWith(
        alerts: updatedAlerts,
        recentlyTriggeredAlert: triggeredAlert,
        message:
            'ALERT TRIGGERED: ${triggeredAlert.symbol} hit \$${triggeredAlert.triggeredPrice?.toStringAsFixed(2)}!',
      ));
    }
  }

  void _onAlertNotificationDismissed(
    AlertNotificationDismissed event,
    Emitter<AlertsState> emit,
  ) {
    final current = state;
    if (current is! AlertsLoaded) return;

    emit(current.copyWith(clearRecentlyTriggered: true));
  }
}
