// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AppStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AppStore on AppStoreBase, Store {
  late final _$isDarkModeAtom = Atom(name: 'AppStoreBase.isDarkMode', context: context);

  @override
  bool get isDarkMode {
    _$isDarkModeAtom.reportRead();
    return super.isDarkMode;
  }

  @override
  set isDarkMode(bool value) {
    _$isDarkModeAtom.reportWrite(value, super.isDarkMode, () {
      super.isDarkMode = value;
    });
  }

  late final _$isUsingSystemThemeAtom = Atom(name: 'AppStoreBase.isUsingSystemTheme', context: context);

  @override
  bool get isUsingSystemTheme {
    _$isUsingSystemThemeAtom.reportRead();
    return super.isUsingSystemTheme;
  }

  @override
  set isUsingSystemTheme(bool value) {
    _$isUsingSystemThemeAtom.reportWrite(value, super.isUsingSystemTheme, () {
      super.isUsingSystemTheme = value;
    });
  }

  late final _$updateFromSystemThemeAsyncAction = AsyncAction('AppStoreBase.updateFromSystemTheme', context: context);

  @override
  Future<void> updateFromSystemTheme() {
    return _$updateFromSystemThemeAsyncAction.run(() => super.updateFromSystemTheme());
  }

  late final _$toggleDarkModeAsyncAction = AsyncAction('AppStoreBase.toggleDarkMode', context: context);

  @override
  Future<void> toggleDarkMode({bool? value, bool save = true, bool isUserChoice = true}) {
    return _$toggleDarkModeAsyncAction.run(() => super.toggleDarkMode(value: value, save: save, isUserChoice: isUserChoice));
  }

  late final _$useSystemThemeAsyncAction = AsyncAction('AppStoreBase.useSystemTheme', context: context);

  @override
  Future<void> useSystemTheme() {
    return _$useSystemThemeAsyncAction.run(() => super.useSystemTheme());
  }

  @override
  String toString() {
    return '''
isDarkMode: ${isDarkMode},
isUsingSystemTheme: ${isUsingSystemTheme}
    ''';
  }
}
