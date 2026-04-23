
# 🍽️ Noogo - Application Mobile Restaurant

> Application Flutter pour la commande de repas en restaurant avec intégration API Laravel

---

## 📋 Informations Projet

| Champ | Valeur |
|-------|--------|
| **Version** | 1.0.0+1 |
| **Date de création** | Mars 2026 |
| **Dernière mise à jour** | Janvier 2026 |
| **Développeur** | QUICK DEV-IT |
| **Flutter SDK** | >=3.0.0 <4.0.0 |
| **Licence** | Propriétaire |
| **Copyright** | © 2026 QUICK DEV-IT |
| **Territoire** | Burkina Faso |

---

## 🚀 Fonctionnalités

### ✅ Implémentées
- 📱 **Scan QR Code** - Scanner le code QR du restaurant pour accéder au menu
- 🍕 **Menu interactif** - Parcourir les plats par catégories
- 🛒 **Panier** - Ajouter/supprimer des articles, gérer les quantités
- 💳 **Paiement** - Support OTP et Mobile Money
- 📦 **Suivi commandes** - Historique et statut en temps réel
- 🔔 **Notifications** - Alertes push et locales
- 👤 **Profil utilisateur** - Gestion compte et mode invité
- 🎨 **Onboarding** - Introduction guidée pour nouveaux utilisateurs

### 🔄 En développement
- 📊 Historique des restaurants visités (API)
- 📍 Géolocalisation restaurant
- ⭐ Système de notation et avis

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Point d'entrée
├── config/
│   └── api_config.dart          # Configuration API & images
├── screens/                     # 11 écrans
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── welcome_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── menu_screen.dart
│   ├── cart_screen.dart
│   ├── orders_screen.dart
│   ├── profile_screen.dart
│   ├── notification_screen.dart
│   └── qr_scanner_screen.dart
├── services/                    # 8 services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── restaurant_provider.dart
│   ├── realtime_service.dart
│   ├── notification_service.dart
│   ├── payment_service.dart
│   ├── history_service.dart
│   └── restaurant_storage_service.dart
├── models/                      # 8 modèles
│   ├── user.dart
│   ├── restaurant.dart
│   ├── dish.dart
│   ├── category.dart
│   ├── order.dart
│   ├── flash_info.dart
│   ├── app_notification.dart
│   └── otp_payment_request.dart
├── widgets/                     # 7 widgets réutilisables
│   ├── custom_app_bar.dart
│   ├── custom_bottom_navigation.dart
│   ├── restaurant_header.dart
│   ├── dishes_grid.dart
│   ├── flash_info_section.dart
│   ├── contact_info.dart
│   └── qr_scanner_overlay.dart
└── utils/                       # 4 utilitaires
    ├── app_colors.dart
    ├── app_text_styles.dart
    ├── app_animations.dart
    └── qr_helper.dart
```

---

## 🛠️ Installation

### Prérequis
- Flutter SDK >= 3.0.0
- Dart SDK
- Android Studio / VS Code
- Émulateur Android ou appareil physique

### Étapes

```bash
# 1. Cloner le dépôt
git clone <repository-url>
cd noogo-app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run

# 4. Build pour production
flutter build apk --release
flutter build ios --release
```

---

## 📦 Dépendances Principales

| Package | Version | Usage |
|---------|---------|-------|
| provider | ^6.0.5 | Gestion d'état |
| http | ^1.5.0 | Appels API REST |
| shared_preferences | ^2.1.1 | Stockage local |
| mobile_scanner | ^7.1.4 | Scanner QR Code |
| pusher_channels_flutter | ^2.5.0 | WebSocket temps réel |
| cached_network_image | ^3.3.0 | Cache images |
| intl | ^0.20.2 | Internationalisation |

---

## ⚙️ Configuration API

L'application se connecte à un backend Laravel :

```
Base URL: https://noogo-e5ygx.ondigitalocean.app/api
Pusher Cluster: eu
```

### Endpoints principaux
- `GET /restaurants/{id}` - Détails restaurant
- `GET /menus/{restaurantId}` - Menu complet
- `POST /orders` - Créer commande
- `POST /verify-otp-payment` - Paiement OTP

---

## 📱 Plateformes Supportées

| Plateforme | Statut | Notes |
|------------|--------|-------|
| Android | ✅ Complet | API 21+ |
| iOS | ✅ Complet | iOS 12+ |
| Web | ⚠️ Partiel | Scanner QR non supporté |
| Windows | ⚠️ Partiel | Scanner QR & Pusher limités |

---

## 🧪 Tests

```bash
# Lancer les tests unitaires
flutter test

# Analyse statique du code
flutter analyze
```

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 📞 Contact

Pour toute question ou contribution, contacter l'équipe de développement.

---

*Dernière mise à jour : 19 mars 2026*
