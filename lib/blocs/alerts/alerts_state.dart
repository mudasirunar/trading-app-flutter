import 'package:equatable/equatable.dart';
import '../../models/alert_model.dart';

abstract class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsLoaded extends AlertsState {
  final List<AlertModel> alerts;
  final AlertModel? recentlyTriggeredAlert;
  final String? message;

  const AlertsLoaded({
    required this.alerts,
    this.recentlyTriggeredAlert,
    this.message,
  });

  /// Alerts actively monitoring price ticks (sorted newest set first)
  List<AlertModel> get activeAlerts {
    final list = alerts.where((a) => a.isActive).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Alerts that have been triggered by market ticks (sorted latest triggered first)
  List<AlertModel> get triggeredAlerts {
    final list = alerts.where((a) => a.isTriggered).toList();
    list.sort((a, b) {
      final timeA = a.triggeredAt ?? a.createdAt;
      final timeB = b.triggeredAt ?? b.createdAt;
      return timeB.compareTo(timeA);
    });
    return list;
  }

  /// Alerts manually paused/disabled by the user (sorted newest set first)
  List<AlertModel> get disabledAlerts {
    final list = alerts.where((a) => a.isDisabled).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Whether a specific symbol currently has at least one active alert
  bool hasActiveAlert(String symbol) {
    return activeAlerts.any(
      (a) => a.symbol.toUpperCase() == symbol.toUpperCase(),
    );
  }

  /// All alerts configured for a specific symbol
  List<AlertModel> getAlertsForSymbol(String symbol) {
    return alerts
        .where((a) => a.symbol.toUpperCase() == symbol.toUpperCase())
        .toList();
  }

  AlertsLoaded copyWith({
    List<AlertModel>? alerts,
    AlertModel? recentlyTriggeredAlert,
    bool clearRecentlyTriggered = false,
    String? message,
  }) {
    return AlertsLoaded(
      alerts: alerts ?? this.alerts,
      recentlyTriggeredAlert: clearRecentlyTriggered
          ? null
          : (recentlyTriggeredAlert ?? this.recentlyTriggeredAlert),
      message: message,
    );
  }

  @override
  List<Object?> get props => [alerts, recentlyTriggeredAlert, message];
}

class AlertsActionFailure extends AlertsState {
  final String errorMessage;
  final AlertsLoaded? previousState;

  const AlertsActionFailure({
    required this.errorMessage,
    this.previousState,
  });

  @override
  List<Object?> get props => [errorMessage, previousState];
}
