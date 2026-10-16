import '../../models/user_model.dart';

/// Abstract contract for authentication operations.
abstract class IAuthRepository {
  /// Retrieves the currently cached session user, if any.
  Future<UserModel?> getCurrentUser();

  /// Authenticates with email and password.
  Future<UserModel> login({
    required String email,
    required String password,
    bool rememberMe = true,
  });

  /// Terminates the current session and clears local credentials.
  Future<void> logout();

  /// Simulates a password reset request.
  Future<void> resetPassword({required String email});
}
