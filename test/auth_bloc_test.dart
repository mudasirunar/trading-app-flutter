import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/auth/auth_bloc.dart';
import 'package:trading_app/blocs/auth/auth_event.dart';
import 'package:trading_app/blocs/auth/auth_state.dart';
import 'package:trading_app/repositories/auth/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepository authRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authRepository = AuthRepository(simulationDelay: Duration.zero);
  });

  group('AuthBloc Unit Tests', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no cached user session exists',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when mudasir@gmail.com logs in with Test123',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'mudasir@gmail.com',
          password: 'Test123',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>()
            .having((s) => s.user.email, 'email', 'mudasir@gmail.com')
            .having((s) => s.user.isPro, 'isPro', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when test@gmail.com logs in with Test123',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'test@gmail.com',
          password: 'Test123',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>()
            .having((s) => s.user.email, 'email', 'test@gmail.com')
            .having((s) => s.user.accountType, 'accountType', 'practice'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when invalid credentials are provided',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'mudasir@gmail.com',
          password: 'WrongPassword!',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          contains('Invalid email or password'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on AuthLogoutRequested',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });
}
