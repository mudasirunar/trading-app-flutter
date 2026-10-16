import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth/i_auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Centralized state manager for user authentication and session lifecycle.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;

  AuthBloc({required IAuthRepository authRepository})
      // ignore: prefer_initializing_formals
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
        rememberMe: event.rememberMe,
      );
      emit(Authenticated(user: user));
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceAll('Exception: ', '')
          : 'An unexpected authentication error occurred.';
      emit(AuthFailure(message: message));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(const Unauthenticated());
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resetPassword(email: event.email);
      emit(AuthPasswordResetSuccess(email: event.email));
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceAll('Exception: ', '')
          : 'Failed to request password reset.';
      emit(AuthFailure(message: message));
    }
  }
}
