import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

abstract class LocalDataSource {
  Future<String> getThemeMode();
  Future<void> cacheThemeMode(String theme);

  Future<String> getLanguageCode();
  Future<void> cacheLanguageCode(String langCode);

  Future<bool> isFirstTime();
  Future<void> setFirstTime(bool isFirstTime);
}

@LazySingleton(as: LocalDataSource)
class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences sharedPreferences;

  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguageCode = 'language_code';
  static const _keyIsFirstTime = 'is_first_time';

  LocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<String> getThemeMode() async {
    return sharedPreferences.getString(_keyThemeMode) ?? 'light';
  }

  @override
  Future<void> cacheThemeMode(String theme) async {
    await sharedPreferences.setString(_keyThemeMode, theme);
  }

  @override
  Future<String> getLanguageCode() async {
    return sharedPreferences.getString(_keyLanguageCode) ?? 'vi';
  }

  @override
  Future<void> cacheLanguageCode(String langCode) async {
    await sharedPreferences.setString(_keyLanguageCode, langCode);
  }

  @override
  Future<bool> isFirstTime() async {
    return sharedPreferences.getBool(_keyIsFirstTime) ?? true;
  }

  @override
  Future<void> setFirstTime(bool isFirstTime) async {
    await sharedPreferences.setBool(_keyIsFirstTime, isFirstTime);
  }
}
