import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import core architecture components
import 'core/constants/app_theme.dart';
import 'core/utils/connectivity_service.dart';
import 'core/di/injection.dart';

import 'core/localization/app_localizations.dart';

// Import Data sources
import 'data/datasources/local_datasource.dart';

// Import Repositories
import 'domain/repositories/recipe_repository.dart';
import 'domain/repositories/user_repository.dart';

// Import Blocs & Cubits
import 'presentation/settings/app_setting_cubit.dart';
import 'presentation/auth/auth_bloc.dart';
import 'presentation/input_hub/ai_recipe_cubit.dart';
import 'presentation/home/calorie_tracker_cubit.dart';
import 'presentation/home/sync_cubit.dart';

// Import Screens
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/main_shell.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize HydratedStorage
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getTemporaryDirectory(),
  );

  // Initialize Dependency Injection
  await configureDependencies();

  runApp(const SmartBiteApp());
}

class SmartBiteApp extends StatelessWidget {
  const SmartBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ConnectivityService>.value(value: getIt<ConnectivityService>()),
        RepositoryProvider<LocalDataSource>.value(value: getIt<LocalDataSource>()),
        RepositoryProvider<RecipeRepository>.value(value: getIt<RecipeRepository>()),
        RepositoryProvider<UserRepository>.value(value: getIt<UserRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppSettingCubit>(
            create: (context) => getIt<AppSettingCubit>(),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
          ),
          BlocProvider<AiRecipeCubit>(
            create: (context) => getIt<AiRecipeCubit>(),
          ),
          BlocProvider<CalorieTrackerCubit>(
            create: (context) => getIt<CalorieTrackerCubit>(),
          ),
          BlocProvider<SyncCubit>(
            create: (context) => getIt<SyncCubit>(),
          ),
        ],
        child: BlocBuilder<AppSettingCubit, AppSettingState>(
          builder: (context, settingsState) {
            return MaterialApp(
              title: 'SmartBite',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settingsState.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
              
              locale: Locale(settingsState.locale),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('vi', ''),
                Locale('en', ''),
              ],

              // Route definitions
              initialRoute: '/login',
              routes: {
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/home': (context) => const MainShell(),
                '/settings': (context) => const SettingsScreen(),
                '/admin': (context) => const AdminDashboard(),
              },
            );
          },
        ),
      ),
    );
  }
}
