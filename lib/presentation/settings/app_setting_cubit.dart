import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';

class AppSettingState extends Equatable {
  final String themeMode; // 'light' | 'dark'
  final String locale; // 'vi' | 'en'

  const AppSettingState({
    required this.themeMode,
    required this.locale,
  });

  AppSettingState copyWith({
    String? themeMode,
    String? locale,
  }) {
    return AppSettingState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];
}

@injectable
class AppSettingCubit extends HydratedCubit<AppSettingState> {
  AppSettingCubit()
      : super(const AppSettingState(themeMode: 'light', locale: 'vi'));

  void toggleTheme() {
    final newTheme = state.themeMode == 'light' ? 'dark' : 'light';
    emit(state.copyWith(themeMode: newTheme));
  }

  void changeLocale(String langCode) {
    emit(state.copyWith(locale: langCode));
  }

  @override
  AppSettingState? fromJson(Map<String, dynamic> json) {
    return AppSettingState(
      themeMode: json['themeMode'] as String? ?? 'light',
      locale: json['locale'] as String? ?? 'vi',
    );
  }

  @override
  Map<String, dynamic>? toJson(AppSettingState state) {
    return {
      'themeMode': state.themeMode,
      'locale': state.locale,
    };
  }
}
