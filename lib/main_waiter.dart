import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:noogo/services/crash_reporting_service.dart';
import 'package:noogo/services/fcm_service.dart';
import 'package:noogo/services/theme_provider.dart';
import 'package:noogo/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'waiter/screens/waiter_login_screen.dart';
import 'waiter/screens/waiter_home_screen.dart';
import 'waiter/services/waiter_provider.dart';
import 'waiter/services/waiter_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/.env');

  try {
    await Firebase.initializeApp();
    await FCMService.init();
    await WaiterNotificationService.instance.initFcmOnly();
  } catch (e) {
    debugPrint('Firebase/WaiterNotif non configuré: $e');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cardBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    originalOnError?.call(details);
    CrashReportingService.captureException(
      details.exception,
      stackTrace: details.stack,
      tag: 'FlutterError',
    );
  };

  await CrashReportingService.init(() async {
    runApp(NoogoWaiterApp(themeProvider: themeProvider));
  });
}

class NoogoWaiterApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const NoogoWaiterApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => WaiterProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Noogo Serveur',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: const _WaiterSplash(),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget? page;
    switch (settings.name) {
      case '/waiter-login':
        page = const WaiterLoginScreen();
      case '/waiter-home':
        page = const WaiterHomeScreen();
    }
    if (page == null) return null;
    return MaterialPageRoute(settings: settings, builder: (_) => page!);
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF1976D2),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textLight,
        onSecondary: AppColors.textLight,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading3,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.dividerColor, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1976D2),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1976D2),
        secondary: AppColors.secondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

// ─── Splash (auth check) ──────────────────────────────────────────────────────

class _WaiterSplash extends StatefulWidget {
  const _WaiterSplash();

  @override
  State<_WaiterSplash> createState() => _WaiterSplashState();
}

class _WaiterSplashState extends State<_WaiterSplash> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AuthService.getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/waiter-home');
    } else {
      Navigator.of(context).pushReplacementNamed('/waiter-login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.room_service_rounded, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Noogo Serveur',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
