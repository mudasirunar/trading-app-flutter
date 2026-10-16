import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/app_bloc_observer.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth/auth_repository.dart';
import 'repositories/auth/i_auth_repository.dart';
import 'views/auth/login_screen.dart';
import 'views/showcase/design_showcase_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  final authRepository = AuthRepository();
  runApp(TradingApp(authRepository: authRepository));
}

class TradingApp extends StatelessWidget {
  final IAuthRepository authRepository;

  const TradingApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository)
            ..add(const AuthCheckRequested()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Trading App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is Authenticated) {
                  return const DesignShowcaseScreen();
                } else if (authState is Unauthenticated || authState is AuthFailure) {
                  return const LoginScreen();
                }
                // Initial session verification (prevents login screen flash for logged-in users)
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
