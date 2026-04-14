# 🗺️ ROADMAP - Noogo App

> Feuille de route du développement de l'application Noogo

**Version actuelle :** 1.0.0+1  
**Dernière mise à jour :** 14 avril 2026  
**Développeur :** QUICK DEV-IT  
**Licence :** Propriétaire  
**Copyright :** © 2026 QUICK DEV-IT. Tous droits réservés.  
**Territoire :** Burkina Faso

---

## 📊 État Actuel du Projet

| Métrique | Valeur | Statut |
| -------- | ------ | ------ |
| Écrans | 11 | ✅ |
| Services | 8 | ✅ |
| Modèles | 8 | ✅ |
| Widgets | 7 | ✅ |
| Tests Flutter | 47 (6 fichiers) | ✅ |
| Tests Laravel | 61 tests · 130+ assertions | ✅ |
| Couverture Tests | ~55% | 🟡 |
| Documentation | 65% | 🟡 |
| Santé globale | 8.2/10 | 🟢 |

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

- [ ] **FEAT-002** : Système de notation post-commande
  - Ajouter écran notation (1-5 étoiles) accessible depuis OrdersScreen
  - Intégrer API backend (endpoint `POST /api/orders/{id}/rate`)

- [ ] **FEAT-003** : Géolocalisation restaurant
  - Afficher distance restaurant
  - Carte interactive

---

## 🕐 Phase 5 — Monitoring & I18N (Backlog)

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

- [ ] **MON-001** : Intégrer analytics (Firebase Analytics ou Mixpanel)

---

## 📁 Structure Fichiers à Créer

```text
noogo-app/
├── .env                          # À CRÉER - Variables environnement
├── .env.example                  # À CRÉER - Template .env
├── LICENSE                       # À CRÉER - Fichier licence MIT
├── CHANGELOG.md                  # À CRÉER - Historique versions
├── test/
│   ├── models/                   # À CRÉER - Tests modèles
│   ├── services/                 # À CRÉER - Tests services
│   └── widgets/                  # À CRÉER - Tests widgets
└── lib/
    └── utils/
        └── logger.dart           # À CRÉER - Service logging
```

---

## 🔒 Fichier .env Suggéré

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

| Phase | Durée | Début | Fin |
| ----- | ----- | ----- | --- |
| Phase 1 - Critiques | 1 semaine | S12 | S12 |
| Phase 2 - Importantes | 2 semaines | S13 | S14 |
| Phase 3 - Optimisations | 2 semaines | S15 | S16 |
| Phase 4 - Évolutions | Continu | S17+ | - |

---

## ✅ Historique des Accomplissements

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

- L'application est fonctionnelle mais nécessite un renforcement pour la production
- Les plugins Pusher et Mobile Scanner ne fonctionnent pas sur Windows/Web
- L'API backend doit implémenter la route `/api/orders`
- Priorité : sécuriser les clés API avant déploiement

---

*Document généré suite à l'audit du 19 mars 2026*
