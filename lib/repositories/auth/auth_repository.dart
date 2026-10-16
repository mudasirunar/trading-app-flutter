import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'i_auth_repository.dart';

/// Production-ready mock implementation of [IAuthRepository] with preset institutional
/// accounts and persistent local session caching.
class AuthRepository implements IAuthRepository {
  static const String _userStorageKey = 'auth_session_user';

  // Preset institutional accounts per PRD Section 3.1
  static final Map<String, ({String password, UserModel user})> _presetAccounts = {
    'mudasir@gmail.com': (
      password: 'Test123',
      user: UserModel(
        id: 'usr_pro_001',
        email: 'mudasir@gmail.com',
        displayName: 'Mudasir Unar',
        token: 'tok_live_pro_mudasir_8892krwysc',
        accountType: 'pro',
        createdAt: DateTime(2026, 1, 15),
      ),
    ),
    'test@gmail.com': (
      password: 'Test123',
      user: UserModel(
        id: 'usr_practice_002',
        email: 'test@gmail.com',
        displayName: 'Test Trader',
        token: 'tok_sim_practice_trader_4496ac7',
        accountType: 'practice',
        createdAt: DateTime(2026, 2, 20),
      ),
    ),
  };

  final SharedPreferences? prefs;
  final Duration simulationDelay;

  AuthRepository({
    this.prefs,
    this.simulationDelay = const Duration(milliseconds: 600),
  });

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await _getPrefs();
      final userJson = prefs.getString(_userStorageKey);
      if (userJson != null && userJson.isNotEmpty) {
        return UserModel.fromJson(userJson);
      }
    } catch (_) {
      // In case of parsing error, return null to prompt login
    }
    return null;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    // Simulate institutional authentication network round-trip
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }

    final normalizedEmail = email.trim().toLowerCase();
    final account = _presetAccounts[normalizedEmail];

    if (account == null || account.password != password) {
      throw Exception('Invalid email or password. Please verify your credentials.');
    }

    final user = account.user;

    if (rememberMe) {
      final prefs = await _getPrefs();
      await prefs.setString(_userStorageKey, user.toJson());
    }

    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userStorageKey);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw Exception('Please provide a valid institutional or personal email.');
    }
  }
}
