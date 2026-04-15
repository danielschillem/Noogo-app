# 🗺️ ROADMAP - Noogo App

> Feuille de route du développement de l'application Noogo

**Version actuelle :** 1.3.0  
**Dernière mise à jour :** 15 avril 2026  
**Développeur :** QUICK DEV-IT  
**Licence :** Propriétaire  
**Copyright :** © 2026 QUICK DEV-IT. Tous droits réservés.  
**Territoire :** Burkina Faso

---

## 📊 État Actuel du Projet

| Métrique | Valeur | Statut |
| -------- | ------ | ------ |
| Écrans | 15 | ✅ |
| Services | 12 | ✅ |
| Modèles | 9 | ✅ |
| Widgets | 8 | ✅ |
| Tests Flutter | 179 (16 fichiers) | ✅ |
| Tests Laravel | 131 tests · 424 assertions | ✅ |
| Couverture modèles/utils | ~80% | 🟢 |
| Couverture globale (lcov) | ~17% | 🟡 |
| Documentation | 90% | 🟢 |
| Santé globale | 9.3/10 | 🟢 |

---

## 🔴 Phase 1 - Corrections Critiques (Immédiat)

### Sécurité & Configuration

- [x] **SEC-001** : Déplacer les clés API vers fichier `.env`
  - Fichier : `lib/services/realtime_service.dart`
  - Risque : 🚨 ÉLEVÉ - Clés Pusher exposées dans le code source
  - Action : Utiliser `flutter_dotenv` (déjà dans pubspec.yaml)
  - ✅ Corrigé le 19/03/2026 - ApiConfig lit maintenant depuis .env

- [x] **SEC-002** : Centraliser les URLs de base
  - Fichiers concernés :
    - `lib/config/api_config.dart`
    - `lib/services/auth_service.dart`
    - `lib/services/realtime_service.dart`
  - Action : Utiliser une seule source de vérité
  - ✅ Corrigé le 19/03/2026 - Tous les services utilisent ApiConfig

### Qualité du Code

- [x] **QA-001** : Supprimer import dupliqué
  - Fichier : `lib/services/auth_service.dart` (ligne 4)
  - Import dupliqué : `dart:convert`
  - ✅ Corrigé le 19/03/2026

- [x] **QA-002** : Ajouter système de logging structuré
  - Remplacer `print()` et `debugPrint()` par un logger unifié
  - Suggéré : package `logger` ou implémentation custom
  - ✅ Créé le 19/03/2026 - `lib/utils/app_logger.dart`

### Documentation

- [x] **DOC-001** : Mettre à jour README.md
  - Ajouter version, développeur, licence
  - Documenter l'architecture
  - Instructions d'installation

- [x] **DOC-002** : Créer ROADMAP.md
  - Documenter les phases de développement
  - Lister les tâches par priorité

---

## 🟠 Phase 2 - Améliorations Importantes (Sprint 1-2)

### Sécurité API Backend

- [x] **SEC-003** : Sécuriser l'endpoint public `storeMobile`
  - Fichier : `backend/app/Http/Controllers/Api/OrderController.php`
  - Risque : Soumission de commandes sans compte, sans limites
  - Actions réalisées le 12/04/2026 :
    - Validation regex téléphone (`/^[\+0-9\s\-]{6,20}$/`)
    - Validation table (alphanumérique uniquement, max 10 chars)
    - Limite panier à 50 plats distincts, quantité max 100 par plat
    - Vérification `is_active = true` du restaurant (→ 404 si fermé)
    - Détection d'articles en double dans le payload (→ 422)

- [x] **SEC-004** : Corriger migration `email NOT NULL` vs nullable
  - Fichier : `backend/database/migrations/0001_01_01_000000_create_users_table.php`
  - Bug : `email NOT NULL` en DB mais nullable dans le contrôleur (crash silencieux en prod)
  - ✅ Corrigé le 12/04/2026 - `email` → `nullable()->unique()`

### API & Services

- [x] **API-001** : Implémenter HistoryService réel avec parallélisme
  - Fichier : `lib/services/history_service.dart`
  - Problème : Appels N+1 séquentiels (20 requêtes pour 20 restaurants)
  - ✅ Corrigé le 12/04/2026 - `Future.wait()` parallèle + filtre nulls

- [x] **API-002** : Ajouter retry logic au PaymentService
  - Fichier : `lib/services/payment_service.dart`
  - ✅ Corrigé le 12/04/2026 :
    - Timeout 20s
    - Retry exponentiel (3 tentatives, backoff 2s/4s)
    - Nouveau type `PaymentResult` avec message d'erreur détaillé
    - Plus d'échec silencieux (`catch (e) { return false }`)

- [x] **API-003** : Créer couche de gestion d'erreurs API
  - ✅ Corrigé le 12/04/2026 :
    - Créé `lib/utils/api_exceptions.dart` (8 classes typées : `NetworkException`, `AuthException`, `ForbiddenException`, `NotFoundException`, `ValidationException`, `RateLimitException`, `ServerException`, `ParseException`)
    - `ApiService._get()` et `_post()` lèvent des exceptions typées avec `ApiException.fromStatusCode()`
    - Tous les `debugPrint` dans ApiService wrappés dans `kDebugMode`

- [x] **API-004** : Ajouter timeout global au scan restaurant
  - ✅ Déjà présent — `WelcomeScreen` implémente un timeout 15s avec `Timer` + fallback UI

### UX & Validation

- [x] **UX-001** : Validation formulaire AuthScreen
  - Fichier : `lib/screens/auth_screen.dart`
  - ✅ Présent - regex téléphone Burkina Faso (`+226`), email, mot de passe

- [x] **UX-002** : Validation formulaire CartScreen
  - ✅ Corrigé le 12/04/2026 :
    - Numéro de table : regex `^[A-Za-z0-9\-]{1,10}$`, messages d'erreur distincts vide/invalide
    - Numéro téléphone : regex BF `^(?:\+?226|00226)?[0-9]{8}$` (déjà présent)
    - Numéro Mobile Money : même regex téléphone BF
    - `debugPrint` du Consumer builder supprimé (PERF)

- [x] **UX-003** : Gérer états vides dans MenuScreen
  - ✅ `_buildDishesSection()` affiche un état vide si la liste de plats est vide
  - ✅ `debugPrint` dans `_buildCategoryItem` supprimé (s'exécutait à chaque rebuild)

### Infrastructure & Déploiement

- [x] **INFRA-001** : Migration Docker vers `serversideup/php:8.3-fpm-nginx`
  - Fichiers : `backend/Dockerfile`, `backend/start.sh`
  - ✅ Corrigé - image prod-ready, nginx.conf fourni

---

## 🟡 Phase 3 - Optimisations (Sprint 3-4)

### Performance & Stabilité

- [x] **PERF-001** : Réduire logging en mode release
  - ✅ Corrigé le 12/04/2026 :
    - `ApiService` : tous les `debugPrint` wrappés dans `if (kDebugMode)`
    - `CartScreen` : `debugPrint('CartScreen rebuild...')` supprimé du Consumer
    - `MenuScreen` : `debugPrint('📸 Category...')` supprimé de `_buildCategoryItem` (s'exécutait à chaque frame)

- [x] **PERF-002** : Implémenter machine d'état pour commandes
  - Fichier : `lib/services/restaurant_provider.dart`
  - ✅ Corrigé le 14/04/2026 :
    - Enum `OrderSubmitState` (idle / submitting / success / error)
    - Getters : `orderSubmitState`, `isSubmittingOrder`, `orderSubmitError`
    - `submitOrder()` transite proprement entre les états + `notifyListeners()`
    - Nouvelle méthode `resetOrderSubmitState()` pour réinitialiser depuis l'UI

- [x] **PERF-003** : Logging échecs images via AppLogger
  - Fichier : `lib/models/dish.dart`
  - ✅ Corrigé le 14/04/2026 :
    - Import `AppLogger` ajouté
    - `fromJson` catch → `AppLogger.error()` (tag: Dish, stackTrace inclus)
    - `_parseImageUrl` catch → `AppLogger.error()`
    - Fallback `defaultImageUrl` → `AppLogger.warning()` (image absente)

### Sécurité Backend (Compléments)

- [x] **SEC-005** : Ajouter Policies Laravel (ownership)
  - ✅ Corrigé le 12/04/2026 :
    - Créé `backend/app/Policies/RestaurantPolicy.php` (méthodes `view/create/update/delete`, `before()` pour admins)
    - Enregistré dans `AppServiceProvider` via `Gate::policy()`
    - `$this->authorize('update', $restaurant)` ajouté dans `store/update/destroy` de `DishController`, `CategoryController`, `FlashInfoController`

- [x] **SEC-006** : Restreindre CORS au domaine Netlify exact
  - ✅ Corrigé le 12/04/2026 :
    - `backend/config/cors.php` : pattern `#^https://noogo-dashboard\.netlify\.app$#` via `NETLIFY_SUBDOMAIN` env var
    - Ajouter `NETLIFY_SUBDOMAIN=noogo-dashboard` dans les variables d'environnement Render

### Tests

- [x] **TEST-001** : Créer tests unitaires modèles Flutter
  - ✅ Créé le 12/04/2026
  - `test/models/dish_test.dart` — 8 tests (parsing JSON, images, prix, formatage)
  - `test/models/order_test.dart` — 19 tests (total, statuts, types, fromJson)

- [x] **TEST-002** : Créer tests unitaires services Flutter
  - ✅ Créé le 12/04/2026
  - `test/services/payment_result_test.dart` — 3 tests (PaymentResult ok/fail)
  - `test/utils/qr_helper_test.dart` — 11 tests (validation/extraction QR)

- [x] **TEST-003** : Créer tests Feature Laravel
  - ✅ Créé le 12/04/2026
  - `tests/Feature/Api/StoreMobileTest.php` — 11 tests (restaurant inactif, doublons, formats…)
  - `tests/Feature/Api/AuthControllerTest.php` — 10 tests (register/login tél et email)

- [x] **TEST-004** : Tests widget Flutter
  - ✅ Créé le 14/04/2026 :
    - `test/widgets/cart_screen_test.dart` — 6 tests (panier vide, articles affichés, quantité, boutons)
    - `test/widgets/home_screen_test.dart` — 5 tests (état chargement, erreur, données disponibles)
    - `_FakeProvider` surclasse `RestaurantProvider` sans appels réseau

- [x] **TEST-005** : Couverture Laravel (OrderController, DishController)
  - ✅ Créé le 14/04/2026 :
    - `tests/Feature/Api/OrderControllerTest.php` — 19 tests (list, show, store, status, cancel, stats)
    - `tests/Feature/Api/DishControllerTest.php` — 21 tests (CRUD plats, ownership, validations)
    - Trait `AuthorizesRequests` ajouté au `Controller` de base

---

## 🟢 Phase 4 - Évolutions Futures (Backlog)

### Internationalisation

**Voir Phase 5**

### Monitoring

**Voir Phase 5**

### Fonctionnalités

- [x] **FEAT-001** : Mode hors-ligne (cache menu)
  - ✅ Corrigé le 14/04/2026 :
    - `lib/services/favorites_service.dart` créé (SharedPreferences)
    - Cache menu local dans `RestaurantProvider` : lecture hors-ligne si API inaccessible
    - Syncronisation automatique au retour connexion

- [x] **FEAT-004** : Favoris & Recommandations (plats)
  - ✅ Corrigé le 14/04/2026 :
    - `FavoritesService` : sauvegarde / lecture / toggle via SharedPreferences
    - `RestaurantProvider` : `favoriteDishes`, `isFavoriteDish()`, `toggleFavoriteDish()`
    - `MenuScreen` : onglet ❤️ « Favoris » dans la barre catégories + icône toggle par plat

- [x] **FEAT-002** : Système de notation post-commande
  - ✅ Corrigé le 14/04/2026 :
    - `lib/services/rating_service.dart` — persistance des notes (SharedPreferences)
    - `lib/widgets/rating_dialog.dart` — dialog 5 étoiles + champ commentaire
    - `OrdersScreen` : bouton **Évaluer** (commandes livrées/terminées), chip **Noté** après soumission

- [x] **FEAT-003** : Géolocalisation restaurant
  - ✅ Corrigé le 14/04/2026 :
    - `geolocator: ^13.0.2` ajouté dans `pubspec.yaml`
    - Permissions Android (`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`) + iOS (`NSLocationWhenInUseUsageDescription`)
    - `lib/services/geolocation_service.dart` — `getDistanceToRestaurant()`, `formatDistance()`, `openMapsForRestaurant()`
    - `lib/models/restaurant.dart` — champs `latitude` / `longitude` optionnels + `_parseDouble()`
    - `ContactInfo` widget — badge distance + bouton **Itinéraire** (Google Maps)
    - Backend : migration `2026_04_14_000001_add_coordinates_to_restaurants_table.php` + `$fillable` + casts `float`

---

## 🕐 Phase 5 — Monitoring & I18N (Backlog)

- [x] **MON-001** : Analytics événements clés
  - ✅ Corrigé le 14/04/2026 :
    - `lib/services/analytics_service.dart` — 12 événements custom (QR, commande, paiement, navigation, user)
    - `ApiConfig.analyticsEndpoint` depuis `.env` (`ANALYTICS_ENDPOINT=`)
    - Log local via `AppLogger` en dev ; envoi POST JSON en production si endpoint configuré
    - Compatible Mixpanel / PostHog / endpoint Laravel custom (1 méthode `_send` à adapater)
    - Appelé automatiquement dans `validateRestaurantQRCode` + `submitOrder`

- [x] **MON-002** : Crash reporting Sentry (`sentry_flutter`)
  - ✅ Corrigé le 14/04/2026 :
    - Package `sentry_flutter: ^8.14.0` ajouté dans `pubspec.yaml`
    - `lib/services/crash_reporting_service.dart` —wrapper Sentry : init, captureException, captureMessage, breadcrumbs, setUser/clearUser
    - `main()` : `FlutterError.onError` capturé + `CrashReportingService.init()` enrobe `runApp`
    - `ApiConfig.sentryDsn` depuis `.env` (`SENTRY_DSN=`)
    - Désactivé si DSN vide — 0 impact en développement
    - `sampleRate` 100% prod / 10% dev ; filtrage `SocketException`/`TimeoutException`

- [x] **I18N-001** : Extraire chaînes vers l10n (ARB FR/EN)
  - ✅ Corrigé le 14/04/2026 :
    - `flutter_localizations` ajouté dans `pubspec.yaml` + `generate: true`
    - `l10n.yaml` : template FR, output `lib/l10n/generated/app_localizations.dart`
    - `lib/l10n/app_fr.arb` — 52 chaînes (écrans cart, orders, menu, auth, notifications, notation…)
    - `lib/l10n/app_en.arb` — traduction complète EN
    - `main.dart` : `localizationsDelegates`, `supportedLocales`, `locale: fr` par défaut
    - Usage : `AppLocalizations.of(context).cartEmpty` dans les widgets

- [x] **MON-001** : Analytics léger custom
  - ✅ Corrigé le 14/04/2026 :
    - `lib/services/analytics_service.dart` — service stateless événements clés : `qrScanned`, `orderPlaced`, `dishAddedToCart`, `orderRated`, `screenViewed`, `userLoggedIn`…
    - En debug : logging via `AppLogger` ; en production : POST JSON vers `ANALYTICS_ENDPOINT` (.env)
    - Intégré dans `RestaurantProvider.submitOrder()` (appel `unawaited` — non-bloquant)
    - Architecture extensible : remplacer `_send()` par SDK Mixpanel/PostHog/Firebase sans changer le reste

---

## � Phase 6 — Dashboard & Mobile v1.1/v1.2 (Avril 2026)

### Dashboard (React + TypeScript)

- [x] **DASH-01** : Coordonnées GPS dans la fiche restaurant
  - ✅ Corrigé le 14/04/2026 :
    - Champs `latitude` / `longitude` dans `RestaurantFormPage.tsx`
    - Bouton **Utiliser ma position** (Geolocation API navigateur)
    - Lien Google Maps en lecture (clickable)
    - Validation côté backend (nullable decimal 10,7)

- [x] **DASH-02** : Toggle ouverture/fermeture manuelle restaurant
  - ✅ Corrigé le 14/04/2026 :
    - Migration `is_open_override` (nullable boolean)
    - Accessor `isOpen` dans le modèle `Restaurant` (override prioritaire sur horaires)
    - Méthode `toggleOpen()` dans `RestaurantController`
    - Route `POST /restaurants/{id}/toggle-open`
    - Badge dual (API + override) dans la liste restaurants
    - Hook API `toggleRestaurantOpen()` côté TypeScript

- [x] **DASH-03** : Galerie images restaurant
  - ✅ Corrigé le 14/04/2026 :
    - Multi-upload galerie dans `RestaurantFormPage.tsx`
    - Suppression individuelle de photo
    - Stockage en mode append (ajout sans écraser)
    - Affichage carrousel dans `RestaurantDetailPage.tsx`

- [x] **DASH-04** : Export CSV des commandes
  - ✅ Déjà présent dans `OrdersPage.tsx` (filtre + export natif)

- [x] **DASH-05** : Auto-refresh Dashboard toutes les 30 secondes
  - ✅ Corrigé le 14/04/2026 :
    - `setInterval` 30 s dans `DashboardPage.tsx` avec `useCallback fetchData`
    - Bouton **Actualiser** manuel + horodatage dernière MàJ
    - Nettoyage de l'intervalle au démontage (`clearInterval`)

- [x] **DASH-06** : Badge commandes en attente dans la Sidebar
  - ✅ Corrigé le 14/04/2026 :
    - Polling 30 s vers `GET /orders?status=pending`
    - Badge rouge animé avec compteur dans la Sidebar
    - Mise à jour automatique à chaque changement de statut

- [x] **DASH-07** : Améliorations Sidebar et liste restaurants
  - ✅ Corrigé le 15/04/2026 :
    - Affichage multi-restaurant (jusqu'à 4 + « Voir N de plus »)
    - Indicateurs statut ouvert/fermé dans la Sidebar
    - `RestaurantsPage.tsx` : barre de stats, onglets Tous/Actifs/Inactifs, tri

### Application Mobile (Flutter)

- [x] **MOB-001** : Persistance multi-restaurants « Scan once, stay forever »
  - ✅ Corrigé le 15/04/2026 :
    - Nouveau modèle `SavedRestaurant` (id, name, imageUrl, address, phone, lastScannedAt)
    - `RestaurantStorageService` refactorisé : `addOrUpdateRestaurant`, `getSavedRestaurants`, `removeRestaurant`
    - Nouvel écran `MyRestaurantsScreen` (liste swipe-to-dismiss, FAB scan)
    - `ClientPrefsService` : persistance téléphone + Mobile Money (SharedPreferences)
    - `WelcomeScreen` : bouton **Mes restaurants** + pré-remplissage du panier
    - Route `/my-restaurants` ajoutée dans `main.dart`

- [x] **MOB-002** : Bouton Mode Démo restauré
  - ✅ Corrigé le 15/04/2026 :
    - Bouton **Mode Démo** visible uniquement en `kDebugMode` dans `WelcomeScreen`

### API Backend (Laravel)

- [x] **API-005** : Réinitialisation mot de passe
  - ✅ Endpoint `POST /auth/forgot-password` + `POST /auth/reset-password`
  - Token sécurisé, expiration 60 min, email Markdown BF

- [x] **API-006** : Rôles & permissions staff (GérantStaff)
  - ✅ Corrigé le 14/04/2026 :
    - Modèle `StaffRole` + table `staff_roles` (owner/manager/server)
    - `StaffController` : inviter/lister/révoquer staff par restaurant
    - Policy `StaffPolicy` (seul le propriétaire gère son staff)
    - 22 tests Feature `StaffControllerTest`

- [x] **D11** : Notifications temps réel (Pusher / Laravel Events)
  - ✅ Corrigé le 14/04/2026 :
    - `OrderStatusChanged` Event → broadcast Pusher channel `orders.{restaurantId}`
    - Hook `usePusher.ts` côté Dashboard React
    - Toast notification en temps réel sur changement de statut commande

---

## �📁 Structure Fichiers à Créer

```text
noogo-app/
├── .env                          # ✅ Créé - Variables environnement
├── assets/env/.env               # ✅ Créé - Variables Flutter dotenv
├── LICENSE                       # ✅ Créé - Fichier licence
├── ROADMAP.md                    # ✅ Créé - Feuille de route
├── test/
│   ├── models/                   # ✅ 5 fichiers (dish, order, app_notification, restaurant, flash_info, saved_restaurant, user)
│   ├── services/                 # ✅ 4 fichiers (favorites, geolocation, payment_result, rating)
│   ├── utils/                    # ✅ 3 fichiers (qr_helper, menu_search, api_exceptions)
│   └── widgets/                  # ✅ 2 fichiers (cart_screen, home_screen)
└── lib/
    ├── models/
    │   └── saved_restaurant.dart  # ✅ Créé - Multi-restaurant persistance
    ├── services/
    │   ├── client_prefs_service.dart  # ✅ Créé - Prefs client (phone + MoMo)
    │   ├── analytics_service.dart     # ✅ Créé - Analytics custom
    │   └── crash_reporting_service.dart # ✅ Créé - Sentry wrapper
    └── screens/
        └── my_restaurants_screen.dart  # ✅ Créé - Liste restaurants scannés
```

---

## � Phase 7 — Push Notifications FCM & Dashboard Redesign (Avril 2026)

### Push Notifications FCM (Firebase Cloud Messaging)

- [x] **FCM-001** : Migration colonne `fcm_token` sur la table `users`
  - ✅ Corrigé le 15/04/2026
  - Colonne `fcm_token` nullable, ajoutée dans `$fillable` du modèle `User`
  - `php artisan migrate` → 131 tests passés, rien de cassé

- [x] **FCM-002** : `FcmNotificationService` Laravel (API Legacy HTTP)
  - ✅ Corrigé le 15/04/2026
  - `notifyNewOrder(Restaurant, Order)` → topic `restaurant_{id}` + token owner
  - `notifyOrderStatusChanged(Order, status)` → token FCM du client
  - Titres avec emojis par statut (🍽️ 🔄 👨‍🍳 🟢 ✅ ❌)
  - Silencieux si `FCM_SERVER_KEY` non configuré (Log::warning)
  - `FCM_SERVER_KEY` lu depuis `config('services.fcm.server_key')`

- [x] **FCM-003** : `DeviceTokenController` + routes
  - ✅ Corrigé le 15/04/2026
  - `POST /api/auth/device-token` → sauvegarde le token
  - `DELETE /api/auth/device-token` → efface à la déconnexion
  - Protégé par `auth:sanctum`

- [x] **FCM-004** : `OrderController` intégration FCM non-bloquante
  - ✅ Corrigé le 15/04/2026
  - `store()` : `notifyNewOrder()` après création (try/catch, non-bloquant)
  - `updateStatus()` : `notifyOrderStatusChanged()` après mise à jour statut

- [x] **FCM-005** : Flutter `FCMService` — enregistrement token + stream
  - ✅ Corrigé le 15/04/2026
  - `registerTokenToBackend(token)` : POST `/auth/device-token` si connecté
  - `unregisterTokenFromBackend()` : DELETE à la déconnexion
  - `onTokenRefresh` → re-register automatique
  - `StreamController<Map> orderEvents` : diffuse les data FCM foreground
  - `_onForeground` : émet sur `orderEvents` si `type == order_status_changed`

- [x] **FCM-006** : Topic restaurant + polling `OrdersScreen`
  - ✅ Corrigé le 15/04/2026
  - `restaurant_provider` : `subscribeToTopic('restaurant_{id}')` au scan QR
  - `OrdersScreen` : `Timer.periodic(15s)` → `forceRefreshOrders()`
  - `FCMService.orderEvents.listen()` → refresh immédiat à la réception FCM
  - Indicateur **Live** animé (pulse vert) dans l'en-tête
  - `dispose()` annule proprement timer + subscription

### Dashboard React — Redesign Professionnel

- [x] **DASH-08** : Design system CSS (`index.css`)
  - ✅ Corrigé le 15/04/2026
  - Variables CSS : `--sidebar-bg: #0f172a`, `--brand: #f97316`, `--radius-card: 16px`
  - Classes utilitaires : `.nav-item`, `.nav-item.active`, `.input-pro`, `.btn-primary`
  - Dégradés : `.stat-card-orange/green/blue/violet`
  - Animations : `fadeIn`, `slideIn`, `pulse`, scrollbar slim

- [x] **DASH-09** : Sidebar dark slate-900
  - ✅ Corrigé le 15/04/2026
  - Fond `#0f172a`, nav items semi-transparents avec hover/active
  - Dot statut restaurant (vert ouvert / jaune fermé / gris inactif)
  - Badge commandes en attente avec animation pulse
  - Menu utilisateur flottant dark avec avatar dégradé orange
  - Mobile : overlay `backdrop-blur` + transition transform

- [x] **DASH-10** : DashboardPage — stat cards dégradées + charts
  - ✅ Corrigé le 15/04/2026
  - **4 stat cards** avec dégradés (orange/vert/bleu/violet), cercles décoratifs, badge tendance `%`
  - **AreaChart** zone remplie pour commandes 7 jours (gradient orange)
  - **BarChart** gradient vert pour revenus 6 mois
  - Panneau commandes récentes avec `StatusBadge` coloré par statut
  - `MiniStatCard` pour les 3 KPIs du bas
  - Loading state avec icône animée `Activity`

- [x] **DASH-11** : LoginPage — split-screen moderne
  - ✅ Corrigé le 15/04/2026
  - Gauche (52%) : fond dark `#0f172a` + blobs décoratifs flous + feature cards + headline dégradé
  - Droite : formulaire épuré avec `input-pro`, toggle mot de passe "Voir/Masquer", `btn-primary` avec flèche
  - Responsive : panneau gauche masqué sur mobile
  - Hint démo discret en bas du formulaire

---

## �🔒 Fichier .env Suggéré

```env
# API Configuration
API_BASE_URL=https://dashboard-noogo.quickdev-it.com/api
IMAGE_BASE_URL=https://dashboard-noogo.quickdev-it.com

# Pusher Configuration
PUSHER_APP_ID=2072946
PUSHER_KEY=c1ae7868685df7094dd2
PUSHER_CLUSTER=eu

# Environment
ENVIRONMENT=development
```

---

## 📅 Planning Estimé

| Phase | Durée | Début | Fin | Statut |
| ----- | ----- | ----- | --- | ------ |
| Phase 1 - Critiques | 1 semaine | S12 | S12 | ✅ Terminé |
| Phase 2 - Importantes | 2 semaines | S13 | S14 | ✅ Terminé |
| Phase 3 - Optimisations | 2 semaines | S15 | S16 | ✅ Terminé |
| Phase 4 - Évolutions | 1 semaine | S16 | S16 | ✅ Terminé |
| Phase 5 - Monitoring & I18N | 1 semaine | S16 | S16 | ✅ Terminé |
| Phase 6 - Dashboard & Mobile v1.2 | 1 semaine | S16 | S16 | ✅ Terminé |
| Phase 7 - FCM Push + Dashboard Redesign | 1 jour | S16 | S16 | ✅ Terminé |

---

## ✅ Historique des Accomplissements

### v1.3.0 (15 Avril 2026)

- ✅ **FCM-001-006** : Notifications push Firebase Cloud Messaging bout en bout
  - Backend : `FcmNotificationService`, `DeviceTokenController`, routes `auth:sanctum`
  - `OrderController` : FCM non-bloquant à la création et au changement de statut
  - Flutter : `FCMService` register/unregister token, `StreamController orderEvents`
  - `OrdersScreen` : polling 15s + écoute stream FCM + indicateur Live animé
  - `restaurant_provider` : subscribe au topic `restaurant_{id}` au scan
- ✅ **DASH-08-11** : Dashboard complet redesign professionnel
  - Design system CSS (design tokens, `.nav-item`, `.btn-primary`, `.input-pro`)
  - Sidebar dark slate-900 avec dots de statut + avatar dégradé
  - DashboardPage : stat cards dégradées, AreaChart commandes, BarChart revenus
  - LoginPage : split-screen dark/clair avec blobs décoratifs
- ✅ 131 tests Laravel, 424 assertions — rien de cassé
- ✅ 0 erreurs TypeScript sur tous les fichiers modifiés

### v1.2.0 (15 Avril 2026)

- ✅ **DASH-01-07** : Dashboard React — GPS, toggle ouverture, galerie images, export CSV, auto-refresh, badge commandes, multi-restaurant Sidebar
- ✅ **MOB-001** : Persistance multi-restaurants (SavedRestaurant, ClientPrefsService, MyRestaurantsScreen, RestaurantStorageService)
- ✅ **MOB-002** : Mode Démo restauré (kDebugMode uniquement)
- ✅ **API-005** : Réinitialisation mot de passe
- ✅ **API-006** : Rôles & permissions staff (StaffController, 22 tests)
- ✅ **D11** : Notifications temps réel Pusher (OrderStatusChanged event + usePusher.ts)
- ✅ 179 tests Flutter (16 fichiers) — +66 nouveaux tests modèles/utils
- ✅ Couverture modèles/utils à ~80%
- ✅ `dart analyze lib/` — 0 issues

### v1.1.0 (14 Avril 2026)

- ✅ Géolocalisation restaurant (`geolocator`, distance, itinéraire Google Maps)
- ✅ Système de notation post-commande (`RatingService`, dialog 5 étoiles)
- ✅ Cache menu hors-ligne (SharedPreferences)
- ✅ Favoris plats avec onglet ❤️ dans MenuScreen
- ✅ Analytics custom (`AnalyticsService`) + Sentry crash reporting
- ✅ Internationalisation (ARB FR/EN, 52 chaînes)
- ✅ Machine d'état `OrderSubmitState` (idle/submitting/success/error)
- ✅ 113 tests Flutter (11 fichiers)

### v1.0.1 (Avril 2026)

- ✅ Machine d'état `OrderSubmitState` (idle / submitting / success / error)
- ✅ Logging structuré des échecs images via `AppLogger`
- ✅ 11 tests widget Flutter (CartScreen + HomeScreen)
- ✅ 19 tests Feature Laravel `OrderControllerTest`
- ✅ 21 tests Feature Laravel `DishControllerTest`
- ✅ 19 tests Feature Laravel `CategoryControllerTest`
- ✅ Throttle 120/min routes dashboard (SEC-007)
- ✅ Cache menu hors-ligne (FEAT-001)
- ✅ Favoris plats avec onglet ❤️ dans MenuScreen (FEAT-004)
- ✅ CORS restreint au domaine Netlify exact
- ✅ Policies Laravel ownership (Restaurant, Dish, Category, FlashInfo)
- ✅ Retry exponentiel PaymentService + 8 classes d'exceptions typées

### v1.0.0 (Mars 2026)

- ✅ Architecture de base complète
- ✅ 11 écrans fonctionnels
- ✅ Intégration API Laravel
- ✅ Scan QR Code
- ✅ Panier et paiement
- ✅ Notifications temps réel (Pusher)
- ✅ Mode invité
- ✅ Thème personnalisé

---

## 📝 Notes

- L'application est production-ready (v1.2.0)
- Flutter 179 tests, 0 issues (`dart analyze`), coverage modèles/utils ~80%
- Laravel 61 tests, 130+ assertions (40 tests de la suite principale)
- Les plugins Pusher et Mobile Scanner ne fonctionnent pas sur Windows/Web (normal)
- Dashboard React déployable sur Netlify, backend Laravel sur Render
- Prochaine étape : tests d'intégration + coverage screens Flutter

---

## 🔭 Backlog — Idées Futures

| ID | Fonctionnalité | Priorité | Effort |
|----|---------------|----------|--------|
| BL-001 | Tests intégration Flutter (golden tests) | 🟡 Moyenne | M |
| BL-002 | Coverage screens Flutter (`lcov`) → 40%+ | 🟡 Moyenne | M |
| BL-003 | Mode tablette / iPad (layout adaptatif) | 🟢 Basse | L |
| BL-004 | Dashboard : page staff redesign (table + avatars) | 🟡 Moyenne | S |
| BL-005 | Dashboard : page menu redesign (grille image) | 🟡 Moyenne | S |
| BL-006 | Dashboard : page commandes redesign (kanban) | 🟠 Haute | M |
| BL-007 | Flutter : onboarding première utilisation | 🟢 Basse | M |
| BL-008 | Backend : rate limiting par IP sur `storeMobile` | 🟠 Haute | S |
| BL-009 | Paiement CinetPay en production (clés réelles) | 🔴 Critique | S |
| BL-010 | Dashboard : notifications push temps réel (WebSocket) | ✅ Terminé | L |

---

*Document mis à jour le 15 avril 2026 — v1.3.0*
