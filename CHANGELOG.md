# CHANGELOG — Noogo App

Tous les changements notables de ce projet sont documentés ici.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Versioning selon [Semantic Versioning](https://semver.org/).

---

## [1.4.1] — 20 avril 2026

### Fonctionnalités ajoutées
- **Livraison** : Option "Livraison" dans le flux de commande (CartScreen) avec saisie d'adresse de livraison
- **Système de notation backend** : Migration `ratings`, modèle `Rating`, `RatingController` (POST + GET), routes API
- **RatingService → API** : Les notes sont désormais envoyées au backend en plus du stockage local
- **Changement de mot de passe** : Endpoint `POST /auth/change-password` + dialog dans ProfileScreen
- **Adresses de livraison** : Dialog fonctionnel (CRUD local SharedPreferences) remplace le stub "à venir"
- **Paramètres de notifications** : Dialog avec toggles (commandes, promos, livraison) remplace le stub

### i18n
- **160+ clés** FR/EN dans les fichiers ARB (vs 63 avant)
- Clés ajoutées : livraison, changement MDP, profil, commandes, navigation, erreurs, confirmations

### Nettoyage
- Suppression de 5 dépendances inutilisées : `badges`, `flutter_spinkit`, `carousel_slider`, `animations`, `qr_flutter`

### Tests
- **1050 tests** — tous passent, 0 erreurs `dart analyze`

---

## [1.4.0] — 19 avril 2026

### Tests ajoutés (BL-001 / BL-002 / BL-003)
- **BL-001** : Golden tests régénérés (`--update-goldens`) — 8 tests visuels (OnboardingScreen slides 1/2/dernier/tablette, WelcomeScreen phone/tablette, CartScreen panier vide/rempli)
- **BL-002** : +56 nouveaux tests Flutter — couverture screens et services élargie
  - `test/screens/forgot_password_screen_test.dart` — 5 tests (step1, bouton, validation, saisie, navigation)
  - `test/screens/payment_screen_test.dart` — 5 tests (providers orange/wave/moov, dispose propre)
  - `test/screens/splash_screen_test.dart` — 3 tests (rendu, layout, dispose animation)
  - `test/services/client_prefs_service_test.dart` — 6 tests (phone, MobileMoney, clear)
  - `test/services/restaurant_storage_service_test.dart` — 12 tests (multi-restaurants, legacy API)
  - `test/models/category_otp_test.dart` — 10 tests (Category.fromJson aliases, OtpPaymentRequest.toJson)
- **BL-003** : `test/utils/responsive_test.dart` — 20 tests layout tablette/iPad/desktop
  - `Responsive.isPhone/isTablet/isDesktop/isSmallPhone/isTabletOrLarger`
  - `Responsive.value()` phone/tablet/desktop
  - `Responsive.gridColumns()` 2/3/4 colonnes
  - `ResponsiveCenter` — rendu phone/tablet, contrainte maxWidth desktop
  - `AdaptivePageLayout` — sidebar masquée sur phone, visible sur tablet, sidebar null

### Confirmé déjà implémenté (backlog vs code réel)
- **BL-004** (Staff page redesign) : ✅ avatars dégradés, stat cards 4 KPIs, search, ROLE_STYLE — déjà en place
- **BL-005** (Menu grille image) : ✅ `DishCard` avec image 62% ratio, badges overlay, vue grille/liste — déjà en place
- **BL-006** (Kanban commandes) : ✅ `OrdersPage` kanban 5 colonnes drag & drop, archive, mini stats — déjà en place

### Technique
- Fix `timersPending` dans les tests d'écrans animés : `pump(Duration(seconds: 25/11))` avant `dispose()`
- Golden images recalibées (`--update-goldens`) après drift de rendu de police

---

## [1.1.0] — 14 avril 2026

### Ajouté
- **FEAT-001** : Cache menu hors-ligne (SharedPreferences) — lecture locale si API inaccessible, synchronisation au retour connexion
- **FEAT-002** : Système de notation post-commande — dialog 5 étoiles + commentaire, bouton Évaluer sur commandes livrées/terminées
- **FEAT-003** : Géolocalisation — badge distance utilisateur↔restaurant (Haversine), bouton Itinéraire  Google Maps, permissions Android/iOS
- **FEAT-004** : Favoris plats — onglet ❤️ dans MenuScreen, toggle par plat, persistance SharedPreferences
- **MON-001** : Service analytics léger — events typés (orderPlaced, qrScanned, dishFavoriteToggled…), POST JSON vers `ANALYTICS_ENDPOINT` en production
- **MON-002** : Crash reporting Sentry via `sentry_flutter` — `FlutterError.onError`, filtre SocketException, configurable via `.env`
- **I18N-001** : Internationalisation ARB FR/EN — 52 chaînes extraites, `flutter_localizations` intégré
- **D11** : Dashboard temps réel Pusher — hook `usePusher`, canal `restaurant.{id}`, événements `order.created` / `order.updated`

### Corrigé
- **SEC-003** : Endpoint `storeMobile` sécurisé (validation regex téléphone/table, limite 50 plats, détection doublons)
- **SEC-004** : Migration `email NOT NULL` → `nullable()` (crash silencieux en production)
- **SEC-005** : Policies Laravel ownership (Restaurant, Dish, Category, FlashInfo)
- **SEC-006** : CORS restreint au domaine dashboard exact via pattern regex
- **PERF-002** : Machine d'état `OrderSubmitState` (idle / submitting / success / error)
- **PERF-003** : Logging images via `AppLogger` (remplacement des `debugPrint` bruts)
- Fix `.env.testing` manquant → `file_get_contents` PHP warning sur tous les tests Laravel (exit code 1)
- Fix syntaxe `orders_screen.dart` (`}` au lieu de `]` pour bloc spread)
- Fix lint `dish.dart` — accolades manquantes dans `if` flow controls

### Dashboard
- **D1** : Page création/édition de restaurant (RestaurantFormPage)
- **D2** : `VITE_IMAGE_BASE_URL` en `.env.production`
- **D3** : Sélecteur de restaurant dans OrdersPage
- **D4** : Graphique revenus BarChart (DashboardPage)
- **D5** : Mini-barre de stats dans OrdersPage
- **D6** : ProfilePage + `updateProfile` dans AuthContext
- **D7** : RestaurantDetailPage — 8 cartes stats + actions rapides
- **D8** : Drag & drop HTML5 réordonnancement catégories/plats (MenuPage)
- **D9** : Sélecteur de restaurant sur DashboardPage (stats par restaurant)
- **D10** : Export CSV commandes (UTF-8 BOM, côté client)
- **D12** : RegisterPage avec validation

### Tests ajoutés
- `tests/Feature/Api/OrderControllerTest.php` — 19 tests
- `tests/Feature/Api/DishControllerTest.php` — 21 tests
- `tests/Feature/Api/StoreMobileTest.php` — 11 tests
- `tests/Feature/Api/AuthControllerTest.php` — 10 tests
- `test/models/dish_test.dart` — 8 tests Flutter
- `test/models/order_test.dart` — 19 tests Flutter
- `test/services/payment_result_test.dart` — 3 tests Flutter
- `test/utils/qr_helper_test.dart` — 11 tests Flutter
- `test/widgets/cart_screen_test.dart` — 6 tests Flutter
- `test/widgets/home_screen_test.dart` — 5 tests Flutter

---

## [1.0.0] — 19 mars 2026

### Ajouté
- Application Flutter complète avec 11 écrans
- Backend Laravel 11 avec API REST
- Dashboard React (Digital Ocean)
- Intégration Pusher (Flutter)
- Scanner QR pour identification restaurant
- Panier + passage de commande (espèces / Mobile Money)
- Suivi de commande en temps réel (polling 30s)
- Push notifications locales
- **SEC-001** : Clés Pusher déplacées vers `.env` (flutter_dotenv)
- **SEC-002** : Centralisation URLs via `ApiConfig`
- **QA-001** : Suppression import dupliqué `dart:convert`
- **QA-002** : Logger structuré `AppLogger`
- **API-001** : HistoryService parallèle (`Future.wait`)
- **API-002** : Retry exponentiel PaymentService (3 tentatives, backoff 2s/4s)
- **API-003** : 8 classes d'exceptions typées (`ApiException`)
- **UX-001/002/003** : Validations formulaires AuthScreen, CartScreen, états vides MenuScreen
- **TEST-001/002** : Tests unitaires modèles et services Flutter
- **TEST-003** : Tests Feature Laravel (StoreMobile, AuthController)
- **INFRA-001** : Dockerfile production (`serversideup/php:8.3-fpm-nginx`)

---

*Maintenu par QUICK DEV-IT — © 2026. Tous droits réservés.*
