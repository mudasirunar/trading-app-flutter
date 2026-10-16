import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial app state before session check completes.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Cold-start state verifying whether a persistent user session exists.
class AuthCheckingSession extends AuthState {
  const AuthCheckingSession();
}

/// In-flight authentication request.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Successfully authenticated with active user profile.
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// No active session; user must log in.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication failed with an error message.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Password reset simulation succeeded.
class AuthPasswordResetSuccess extends AuthState {
  final String email;

  const AuthPasswordResetSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}
