import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Central BlocObserver to log all financial state changes and events.
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    developer.log('Bloc Event [${bloc.runtimeType}]: $event', name: 'AppBloc');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    developer.log('Bloc Change [${bloc.runtimeType}]: currentState=${change.currentState} -> nextState=${change.nextState}', name: 'AppBloc');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    developer.log('Bloc Error [${bloc.runtimeType}]: $error', error: error, stackTrace: stackTrace, name: 'AppBloc');
  }
}
