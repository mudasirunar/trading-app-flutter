import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/app_bloc_observer.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/market/market_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth/auth_repository.dart';
import 'repositories/auth/i_auth_repository.dart';
import 'repositories/market/i_market_repository.dart';
import 'repositories/market/market_repository.dart';
import 'views/auth/login_screen.dart';
import 'views/navigation/main_navigation_hub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  final authRepository = AuthRepository();
  final marketRepository = MarketRepository();
  runApp(
    TradingApp(
      authRepository: authRepository,
      marketRepository: marketRepository,
    ),
  );
}

class TradingApp extends StatelessWidget {
  final IAuthRepository authRepository;
  final IMarketRepository marketRepository;

  TradingApp({
    super.key,
    required this.authRepository,
    IMarketRepository? marketRepository,
  }) : marketRepository = marketRepository ?? MarketRepository();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>.value(value: authRepository),
        RepositoryProvider<IMarketRepository>.value(value: marketRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository: authRepository)
              ..add(const AuthCheckRequested()),
          ),
          BlocProvider<MarketBloc>(
            create: (_) => MarketBloc(marketRepository: marketRepository),
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
                  return const MainNavigationHub();
                }
                // Show full-screen loader on cold-start session verification to prevent login flash
                if (authState is AuthInitial || authState is AuthCheckingSession) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }
                // Keep LoginScreen mounted during AuthLoading, Unauthenticated, and AuthFailure
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    ),
    );
  }
}
