// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/datasources/firebase_datasource.dart' as _i327;
import '../../data/datasources/gemini_datasource.dart' as _i888;
import '../../data/datasources/local_datasource.dart' as _i17;
import '../../data/datasources/sqlite_helper.dart' as _i55;
import '../../data/repositories/recipe_repository_impl.dart' as _i869;
import '../../data/repositories/user_repository_impl.dart' as _i790;
import '../../domain/repositories/recipe_repository.dart' as _i197;
import '../../domain/repositories/user_repository.dart' as _i271;
import '../../domain/usecases/generate_recipe.dart' as _i114;
import '../../presentation/auth/auth_bloc.dart' as _i21;
import '../../presentation/home/calorie_tracker_cubit.dart' as _i533;
import '../../presentation/home/sync_cubit.dart' as _i1011;
import '../../presentation/input_hub/ai_recipe_cubit.dart' as _i266;
import '../../presentation/settings/app_setting_cubit.dart' as _i590;
import '../utils/connectivity_service.dart' as _i501;
import '../utils/sync_manager.dart' as _i660;
import 'injection.dart' as _i464;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.factory<_i533.CalorieTrackerCubit>(() => _i533.CalorieTrackerCubit());
    gh.factory<_i590.AppSettingCubit>(() => _i590.AppSettingCubit());
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => registerModule.firebaseFirestore,
    );
    gh.lazySingleton<_i55.SqliteHelper>(() => _i55.SqliteHelper());
    gh.lazySingleton<_i327.FirebaseDataSource>(
      () => _i327.FirebaseDataSourceImpl(),
    );
    gh.lazySingleton<_i888.GeminiDataSource>(
      () => _i888.GeminiDataSourceImpl(),
    );
    gh.lazySingleton<_i501.ConnectivityService>(
      () => _i501.ConnectivityService(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i197.RecipeRepository>(
      () => _i869.RecipeRepositoryImpl(
        gh<_i888.GeminiDataSource>(),
        gh<_i55.SqliteHelper>(),
        gh<_i501.ConnectivityService>(),
      ),
    );
    gh.lazySingleton<_i17.LocalDataSource>(
      () => _i17.LocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i271.UserRepository>(
      () => _i790.UserRepositoryImpl(
        gh<_i327.FirebaseDataSource>(),
        gh<_i501.ConnectivityService>(),
      ),
    );
    gh.lazySingleton<_i114.GenerateRecipe>(
      () => _i114.GenerateRecipe(gh<_i197.RecipeRepository>()),
    );
    gh.lazySingleton<_i660.SyncManager>(
      () => _i660.SyncManager(
        gh<_i501.ConnectivityService>(),
        gh<_i55.SqliteHelper>(),
      ),
    );
    gh.factory<_i21.AuthBloc>(() => _i21.AuthBloc(gh<_i271.UserRepository>()));
    gh.factory<_i1011.SyncCubit>(
      () => _i1011.SyncCubit(
        gh<_i660.SyncManager>(),
        gh<_i501.ConnectivityService>(),
      ),
    );
    gh.factory<_i266.AiRecipeCubit>(
      () => _i266.AiRecipeCubit(gh<_i114.GenerateRecipe>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i464.RegisterModule {}
