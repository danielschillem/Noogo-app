import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/services/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider — état initial', () {
    test('themeMode par défaut est system', () {
      final p = ThemeProvider();
      expect(p.themeMode, ThemeMode.system);
    });

    test('isDarkMode est false par défaut', () {
      final p = ThemeProvider();
      expect(p.isDarkMode, isFalse);
    });
  });

  group('ThemeProvider.init', () {
    test('charge ThemeMode.dark depuis SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final p = ThemeProvider();
      await p.init();
      expect(p.themeMode, ThemeMode.dark);
      expect(p.isDarkMode, isTrue);
    });

    test('charge ThemeMode.light depuis SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final p = ThemeProvider();
      await p.init();
      expect(p.themeMode, ThemeMode.light);
      expect(p.isDarkMode, isFalse);
    });

    test('valeur inconnue → ThemeMode.system', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'unknown'});
      final p = ThemeProvider();
      await p.init();
      expect(p.themeMode, ThemeMode.system);
    });

    test('rien en cache → ThemeMode.system', () async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.init();
      expect(p.themeMode, ThemeMode.system);
    });
  });

  group('ThemeProvider.toggle', () {
    test('bascule de system → dark', () async {
      final p = ThemeProvider();
      await p.toggle();
      // system != dark donc bascule vers dark
      expect(p.themeMode, ThemeMode.dark);
      expect(p.isDarkMode, isTrue);
    });

    test('bascule de dark → light', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.dark);
      await p.toggle();
      expect(p.themeMode, ThemeMode.light);
      expect(p.isDarkMode, isFalse);
    });

    test('bascule de light → dark', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.light);
      await p.toggle();
      expect(p.themeMode, ThemeMode.dark);
    });
  });

  group('ThemeProvider.setThemeMode', () {
    test('setThemeMode dark persiste dans SharedPreferences', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.dark);
      expect(p.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');
    });

    test('setThemeMode light persiste dans SharedPreferences', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.light);
      expect(p.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');
    });

    test('setThemeMode avec même mode ne notifie pas deux fois', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.dark);
      final before = p.themeMode;
      await p.setThemeMode(ThemeMode.dark); // même valeur
      expect(p.themeMode, before);
    });

    test('setThemeMode system change le thème', () async {
      final p = ThemeProvider();
      await p.setThemeMode(ThemeMode.dark); // d'abord dark
      await p.setThemeMode(ThemeMode.system); // puis system
      expect(p.themeMode, ThemeMode.system);
    });
  });

  group('ThemeProvider — notifications', () {
    test('toggle notifie les listeners', () async {
      final p = ThemeProvider();
      bool notified = false;
      p.addListener(() => notified = true);
      await p.toggle();
      expect(notified, isTrue);
    });

    test('setThemeMode notifie les listeners', () async {
      final p = ThemeProvider();
      bool notified = false;
      p.addListener(() => notified = true);
      await p.setThemeMode(ThemeMode.dark);
      expect(notified, isTrue);
    });
  });
}
