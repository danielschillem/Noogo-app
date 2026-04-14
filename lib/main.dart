import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:noogo/services/crash_reporting_service.dart';
import 'package:noogo/services/deep_link_service.dart';
import 'package:noogo/services/fcm_service.dart';
import 'package:noogo/services/restaurant_storage_service.dart';
import 'package:noogo/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/restaurant_provider.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/env/.env');

  // Initialiser Firebase (requis pour FCM)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase non configuré: $e');
  }

  // Charger le thème sauvegardé avant le premier frame
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cardBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // MON-002 : Capture des erreurs Flutter non gérées
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
    runApp(NooqoApp(themeProvider: themeProvider));
  });
}

class NooqoApp extends StatefulWidget {
  final ThemeProvider themeProvider;

  const NooqoApp({super.key, required this.themeProvider});

  @override
  State<NooqoApp> createState() => _NooqoAppState();
}

class _NooqoAppState extends State<NooqoApp> {
  /// Clé globale pour accéder au Navigator sans BuildContext (deep links)
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<int>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Initialiser FCM
    await FCMService.init();

    // Initialiser les deep links
    await DeepLinkService.init();
    _deepLinkSub =
        DeepLinkService.restaurantIdStream.listen(_onDeepLinkRestaurant);
  }

  /// Appelé quand un deep link noogo://restaurant/{id} est reçu.
  void _onDeepLinkRestaurant(int restaurantId) {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;

    final qrUrl =
        'https://dashboard-noogo.quickdev-it.com/restaurant/$restaurantId';

    // Charger le restaurant via le provider
    ctx.read<RestaurantProvider>().validateRestaurantQRCode(qrUrl).then((_) {
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/home', (route) => false);
    }).catchError((_) {
      // Restaurant invalide — on reste sur l'écran courant
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Noogo',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.themeMode,

            // I18N-001 : Localisation FR/EN
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),

            // Page d'accueil = SplashChecker
            home: const SplashChecker(),

            // Routes nommées avec transitions fade
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  /// Routes nommées avec transition fade-through.
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget? page;
    switch (settings.name) {
      case '/onboarding':
        page = const OnboardingScreen();
      case '/welcome':
        page = const WelcomeScreen();
      case '/home':
        page = const HomeScreen();
    }
    if (page == null) return null;
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page!,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // ─── Thème clair ──────────────────────────────────────────────────────────

  ThemeData _buildLightTheme() => _buildTheme();

  // ─── Thème sombre ─────────────────────────────────────────────────────────

  ThemeData _buildDarkTheme() {
    const darkBg = Color(0xFF0F0F0F);
    const darkSurface = Color(0xFF1C1C1E);
    const darkCard = Color(0xFF2C2C2E);
    const darkText = Color(0xFFF0F0F0);
    const darkTextSec = Color(0xFF8E8E93);
    const darkDivider = Color(0xFF38383A);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
          fontFamily: 'Roboto',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: darkTextSec,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkDivider, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: darkTextSec),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
          fontFamily: 'Roboto',
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: darkTextSec,
          fontFamily: 'Roboto',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : darkTextSec,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.4)
              : darkSurface,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: _createMaterialColor(AppColors.primary),
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
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
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadowColor,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.heading3,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelPadding: EdgeInsets.symmetric(horizontal: 16),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: AppColors.dividerColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shadowColor: AppColors.shadowColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.dividerColor, width: 0.5),
        ),
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
        thumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: (AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBackground,
        elevation: 8,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTextStyles.heading3,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: (AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        disabledColor: AppColors.surface.withValues(alpha: 0.5),
        labelStyle: AppTextStyles.bodySmall,
        secondaryLabelStyle: (AppTextStyles.bodySmall).copyWith(
          color: AppColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        pressElevation: 4,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        displaySmall: AppTextStyles.heading3,
        headlineMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.caption,
      ),
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    final List strengths = <double>[.05];
    final Map<int, Color> swatch = {};
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.toARGB32(), swatch);
  }
}

// ✅ WIDGET QUI VÉRIFIE SI L'ONBOARDING A ÉTÉ VU ET INITIALISE PUSHER
class SplashChecker extends StatefulWidget {
  const SplashChecker({super.key});

  @override
  State<SplashChecker> createState() => _SplashCheckerState();
}

class _SplashCheckerState extends State<SplashChecker> {
  bool _showSplash = true;
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initialisation de l\'application...');

      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      // Vérifier si un restaurant a déjà été scanné
      final isRestaurantScanned =
          await RestaurantStorageService.isRestaurantScanned();
      final restaurantId = await RestaurantStorageService.getRestaurantId();

      if (!mounted) return; // ✅ Vérification early return

      final provider = Provider.of<RestaurantProvider>(context, listen: false);

      // Récupérer les identifiants utilisateur
      final userId = prefs.getString('user_id');
      final authToken = prefs.getString('auth_token');

      // Initialiser le provider (Pusher)
      await provider.initialize(
        userId: userId ?? '1',
        authToken: authToken,
      );

      if (!mounted) return; // ✅ Vérification après async

      // Si restaurant scanné, charger les données
      if (isRestaurantScanned && restaurantId != null) {
        debugPrint('✅ Restaurant déjà scanné (ID: $restaurantId)');

        try {
          await provider
              .loadAllInitialData(
            restaurantId: int.parse(restaurantId),
          )
              .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Timeout lors du chargement');
            },
          );

          if (!mounted) return; // ✅ Vérification après async

          if (provider.restaurant == null) {
            throw Exception('Restaurant non chargé');
          }

          debugPrint('✅ Restaurant chargé: ${provider.restaurant!.nom}');

          // Marquer comme initialisé
          if (mounted) {
            setState(() {});
          }

          // Attendre la fin du splash screen
          await _waitForSplash();

          if (!mounted) return; // ✅ Vérification avant navigation

          // Naviguer vers l'accueil
          Navigator.of(context).pushReplacementNamed('/home');
          return;
        } catch (e) {
          debugPrint('❌ Erreur chargement restaurant: $e');
          await RestaurantStorageService.clearRestaurantData();
          if (!mounted) return; // ✅ Vérification après async
        }
      }

      // Marquer comme initialisé
      if (mounted) setState(() {});

      // Attendre la fin du splash screen
      await _waitForSplash();

      if (!mounted) return; // ✅ Vérification avant navigation

      // Navigation normale
      if (onboardingComplete) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation: $e');

      if (mounted) setState(() {});

      await _waitForSplash();

      if (!mounted) return; // ✅ Vérification avant navigation

      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return; // ✅ Dernière vérification

      if (onboardingComplete) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  Future<void> _waitForSplash() async {
    // Attendre que le splash screen soit terminé
    while (_showSplash && mounted) {
      // ✅ Vérifier mounted
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return AnimatedSplashScreen(
        onInitializationComplete: _onSplashComplete,
      );
    }

    // ✅ ÉCRAN DE CHARGEMENT UNIQUE (suppression du doublon)
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.primary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu_sharp,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Nom de l'app
              const Text(
                'NOOGO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              // Message d'initialisation dynamique
              Consumer<RestaurantProvider>(
                builder: (context, provider, child) {
                  String message = 'Chargement...';

                  if (provider.isRealtimeConnected) {
                    message = '✅ Connecté en temps réel';
                  }

                  if (provider.isLoading) {
                    message = '📡 Chargement des données...';
                  }

                  if (provider.restaurant != null && !provider.isLoading) {
                    message = '✅ ${provider.restaurant!.nom}';
                  }

                  return Column(
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (provider.isRealtimeConnected)
                        const Text(
                          'Pusher actif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 48),

              // Indicateur de chargement
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
