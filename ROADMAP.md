# 🗺️ ROADMAP - Noogo App

> Feuille de route du développement de l'application Noogo

**Version actuelle :** 1.0.0+1  
**Dernière mise à jour :** 19 mars 2026  
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
| Couverture Tests | 0% | 🔴 |
| Documentation | 30% | 🟡 |
| Santé globale | 6/10 | 🟡 |

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

### API & Services

- [ ] **API-001** : Implémenter HistoryService réel
  - Fichier : `lib/services/history_service.dart`
  - Statut actuel : Données simulées (mock)
  - Action : Connecter à l'endpoint API réel

- [ ] **API-002** : Ajouter retry logic au PaymentService
  - Fichier : `lib/services/payment_service.dart`
  - Problèmes actuels :
    - Pas de gestion timeout
    - Échec silencieux
    - Pas de mécanisme de retry
  - Action : Implémenter exponential backoff

- [ ] **API-003** : Créer couche de gestion d'erreurs API
  - Créer des exceptions typées
  - Centraliser le handling dans ApiService
  - Ajouter circuit breaker pattern

- [ ] **API-004** : Ajouter timeout global au scan restaurant
  - Fichier : `lib/screens/welcome_screen.dart`
  - Risque : Loading infini si backend lent

### UX & Validation

- [ ] **UX-001** : Validation formulaire AuthScreen
  - Fichier : `lib/screens/auth_screen.dart`
  - Valider format téléphone
  - Valider longueur mot de passe
  - Valider format email

- [ ] **UX-002** : Validation formulaire CartScreen
  - Fichier : `lib/screens/cart_screen.dart`
  - Valider numéro de table
  - Valider numéro téléphone
  - Valider champs Mobile Money

- [ ] **UX-003** : Gérer états vides dans MenuScreen
  - Fichier : `lib/screens/menu_screen.dart`
  - Afficher message si aucun plat
  - Afficher message si aucune catégorie

---

## 🟡 Phase 3 - Optimisations (Sprint 3-4)

### Performance & Stabilité

- [ ] **PERF-001** : Réduire logging en mode release
  - Conditionner tous les logs avec `kDebugMode`
  - Nettoyer les logs verbeux dans les modèles

- [ ] **PERF-002** : Implémenter machine d'état pour commandes
  - Fichier : `lib/services/restaurant_provider.dart`
  - Problème : États intermédiaires perdus
  - Solution : Queue ou event stream

- [ ] **PERF-003** : Améliorer logging échec images
  - Fichier : `lib/models/dish.dart`
  - Logger les échecs de parsing image en debug

### Tests

- [ ] **TEST-001** : Créer tests unitaires modèles
  - Tester parsing JSON
  - Tester getters calculés
  - Couvrir edge cases

- [ ] **TEST-002** : Créer tests unitaires services
  - Tester ApiService
  - Tester AuthService
  - Mocker les appels HTTP

- [ ] **TEST-003** : Créer tests widget
  - Tester écrans principaux
  - Tester widgets réutilisables

---

## 🟢 Phase 4 - Évolutions Futures (Backlog)

### Internationalisation

- [ ] **I18N-001** : Extraire chaînes vers l10n
  - Utiliser package `intl` (déjà présent)
  - Créer fichiers ARB pour FR/EN

### Monitoring

- [ ] **MON-001** : Intégrer analytics
  - Suggéré : Firebase Analytics ou Mixpanel
  - Tracker événements clés (scan, commande, paiement)

- [ ] **MON-002** : Intégrer crash reporting
  - Suggéré : Firebase Crashlytics ou Sentry
  - Capturer erreurs non gérées

### Fonctionnalités

- [ ] **FEAT-001** : Mode hors-ligne
  - Cache local avec SQLite ou Hive
  - Synchronisation au retour connexion

- [ ] **FEAT-002** : Système de notation
  - Ajouter écran notation post-commande
  - Intégrer API backend

- [ ] **FEAT-003** : Géolocalisation restaurant
  - Afficher distance restaurant
  - Carte interactive

- [ ] **FEAT-004** : Favoris & Recommandations
  - Sauvegarder plats favoris
  - Algorithme de recommandation

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
