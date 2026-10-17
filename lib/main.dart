import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/app_bloc_observer.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/market/market_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
import 'blocs/watchlist/watchlist_bloc.dart';
import 'blocs/watchlist/watchlist_event.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth/auth_repository.dart';
import 'repositories/auth/i_auth_repository.dart';
import 'repositories/market/i_market_repository.dart';
import 'repositories/market/market_repository.dart';
import 'repositories/watchlist/i_watchlist_repository.dart';
import 'repositories/watchlist/watchlist_repository.dart';
import 'services/storage/local_storage_service.dart';
import 'views/auth/login_screen.dart';
import 'blocs/trading/trading_bloc.dart';
import 'blocs/trading/trading_event.dart';
import 'blocs/market/market_state.dart';
import 'repositories/trading/i_trading_repository.dart';
import 'repositories/trading/trading_repository.dart';
import 'views/navigation/main_navigation_hub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  final storageService = LocalStorageService();
  await storageService.init();
  final authRepository = AuthRepository();
  final marketRepository = MarketRepository();
  final watchlistRepository = WatchlistRepository(storageService: storageService);
  final tradingRepository = TradingRepository(storage: storageService);
  runApp(
    TradingApp(
      authRepository: authRepository,
      marketRepository: marketRepository,
      watchlistRepository: watchlistRepository,
      tradingRepository: tradingRepository,
    ),
  );
}

class TradingApp extends StatelessWidget {
  final IAuthRepository authRepository;
  final IMarketRepository marketRepository;
  final IWatchlistRepository watchlistRepository;
  final ITradingRepository tradingRepository;

  TradingApp({
    super.key,
    required this.authRepository,
    IMarketRepository? marketRepository,
    IWatchlistRepository? watchlistRepository,
    ITradingRepository? tradingRepository,
  })  : marketRepository = marketRepository ?? MarketRepository(),
        watchlistRepository = watchlistRepository ??
            WatchlistRepository(storageService: LocalStorageService()),
        tradingRepository = tradingRepository ??
            TradingRepository(storage: LocalStorageService());

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>.value(value: authRepository),
        RepositoryProvider<IMarketRepository>.value(value: marketRepository),
        RepositoryProvider<IWatchlistRepository>.value(value: watchlistRepository),
        RepositoryProvider<ITradingRepository>.value(value: tradingRepository),
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
          BlocProvider<WatchlistBloc>(
            create: (_) => WatchlistBloc(repository: watchlistRepository)
              ..add(const WatchlistsLoadRequested()),
          ),
          BlocProvider<TradingBloc>(
            create: (ctx) {
              final bloc = TradingBloc(repository: tradingRepository)
                ..add(const TradingInitialized());
              ctx.read<MarketBloc>().stream.listen((mState) {
                if (mState is MarketLoaded) {
                  for (final inst in mState.instruments) {
                    bloc.add(MarketTickEvaluated(instrument: inst));
                  }
                }
              });
              return bloc;
            },
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
