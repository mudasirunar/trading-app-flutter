import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Checked on app startup to restore existing session.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Dispatched when the user submits credentials on the login screen.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

/// Dispatched to terminate current session.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Dispatched to request a password reset simulation.
class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
