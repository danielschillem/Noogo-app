# 🍽️ Noogo - Plateforme de Restauration Complète

> Application de commande de repas avec application mobile Flutter, backend Laravel et dashboard React

---

## 📋 Informations Projet

| Champ | Valeur |
|-------|--------|
| **Version** | 1.0.0 |
| **Date de création** | Mars 2026 |
| **Dernière mise à jour** | Janvier 2026 |
| **Développeur** | QUICK DEV-IT |
| **Licence** | Propriétaire |
| **Copyright** | © 2026 QUICK DEV-IT. Tous droits réservés. |

---

## 🏗️ Architecture du Projet

Le projet Noogo est composé de trois parties principales :

```
noogo-app/
├── 📱 / (Flutter App)          # Application mobile client
├── 🖥️ backend/                 # API Laravel
└── 📊 dashboard/               # Dashboard React Admin
```

### 1. Application Mobile Flutter (`/`)
Application client pour les utilisateurs finaux permettant de :
- Scanner les QR codes des restaurants
- Parcourir les menus
- Passer des commandes
- Suivre les commandes en temps réel
- Gérer son profil

### 2. Backend Laravel (`/backend`)
API RESTful pour gérer toutes les données :
- Authentification (Sanctum)
- Gestion des restaurants
- Gestion des menus (catégories, plats)
- Gestion des commandes
- Promotions et offres

### 3. Dashboard React (`/dashboard`)
Interface d'administration pour les restaurateurs :
- Vue d'ensemble des statistiques
- Gestion des restaurants
- Gestion des menus
- Suivi des commandes en temps réel
- Gestion des promotions

---

## 🚀 Installation

### Prérequis
- **Flutter SDK** >= 3.0.0
- **PHP** >= 8.2
- **Composer**
- **Node.js** >= 18
- **npm** ou **yarn**

### 1. Installation du Backend Laravel

```bash
cd backend

# Installer les dépendances
composer install

# Configurer l'environnement
cp .env.example .env
php artisan key:generate

# Configurer la base de données (SQLite par défaut)
touch database/database.sqlite
php artisan migrate --seed

# Créer le lien symbolique pour le storage
php artisan storage:link

# Démarrer le serveur
php artisan serve
```

**Identifiants de démo :**
- Admin : `admin@noogo.com` / `password`
- Propriétaire : `owner@noogo.com` / `password`

### 2. Installation du Dashboard React

```bash
cd dashboard

# Installer les dépendances
npm install

# Démarrer en mode développement
npm run dev
```

Le dashboard sera accessible sur `http://localhost:5173`

### 3. Installation de l'App Flutter

```bash
# À la racine du projet
flutter pub get
flutter run
```

---

## 📡 API Endpoints

### Authentification
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |
| POST | `/api/auth/logout` | Déconnexion |
| GET | `/api/auth/me` | Utilisateur actuel |

### Restaurants
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/restaurants` | Liste des restaurants |
| POST | `/api/restaurants` | Créer un restaurant |
| GET | `/api/restaurants/{id}` | Détails restaurant |
| PUT | `/api/restaurants/{id}` | Modifier restaurant |
| DELETE | `/api/restaurants/{id}` | Supprimer restaurant |
| GET | `/api/restaurant/{id}/menu` | Menu complet (public) |

### Catégories
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/restaurants/{id}/categories` | Liste catégories |
| POST | `/api/restaurants/{id}/categories` | Créer catégorie |
| PUT | `/api/restaurants/{id}/categories/{catId}` | Modifier |
| DELETE | `/api/restaurants/{id}/categories/{catId}` | Supprimer |

### Plats
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/restaurants/{id}/dishes` | Liste plats |
| POST | `/api/restaurants/{id}/dishes` | Créer plat |
| PUT | `/api/restaurants/{id}/dishes/{dishId}` | Modifier |
| DELETE | `/api/restaurants/{id}/dishes/{dishId}` | Supprimer |
| POST | `/api/restaurants/{id}/dishes/{dishId}/toggle-availability` | Basculer disponibilité |

### Commandes
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/restaurants/{id}/orders` | Liste commandes |
| POST | `/api/restaurants/{id}/orders` | Nouvelle commande |
| PATCH | `/api/restaurants/{id}/orders/{orderId}/status` | Modifier statut |

### Offres/Promotions
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/offres/actives/{restaurantId}` | Offres actives (public) |
| GET | `/api/restaurants/{id}/flash-infos` | Toutes les offres |
| POST | `/api/restaurants/{id}/flash-infos` | Créer offre |

---

## 🗄️ Structure Base de Données

### Tables principales

**users**
- id, name, email, password, phone, is_admin

**restaurants**
- id, user_id, nom, telephone, adresse, email, logo, description, heures_ouverture, images, is_active, qr_code

**categories**
- id, restaurant_id, nom, description, image, ordre, is_active

**dishes**
- id, restaurant_id, category_id, nom, description, prix, images, disponibilite, is_plat_du_jour, temps_preparation, ordre

**orders**
- id, restaurant_id, user_id, customer_name, customer_phone, status, order_type, table_number, total_amount, payment_method, notes

**order_items**
- id, order_id, dish_id, quantity, unit_price, total_price, special_instructions

**flash_infos**
- id, restaurant_id, titre, description, image, type, reduction_percentage, prix_special, date_debut, date_fin, is_active

---

## 🔧 Configuration

### Backend (.env)
```env
APP_NAME="Noogo Dashboard"
APP_URL=http://localhost:8000
DB_CONNECTION=sqlite
FRONTEND_URL=http://localhost:5173
SANCTUM_STATEFUL_DOMAINS=localhost:5173,localhost:3000
```

### Frontend (.env)
```env
VITE_API_URL=http://localhost:8000/api
```

### Flutter (.env)
```env
API_BASE_URL=http://localhost:8000/api
IMAGE_BASE_URL=http://localhost:8000
```

---

## 📁 Structure des Fichiers

### Backend Laravel
```
backend/
├── app/
│   ├── Http/Controllers/Api/
│   │   ├── AuthController.php
│   │   ├── RestaurantController.php
│   │   ├── CategoryController.php
│   │   ├── DishController.php
│   │   ├── OrderController.php
│   │   ├── FlashInfoController.php
│   │   └── DashboardController.php
│   └── Models/
│       ├── User.php
│       ├── Restaurant.php
│       ├── Category.php
│       ├── Dish.php
│       ├── Order.php
│       ├── OrderItem.php
│       └── FlashInfo.php
├── database/migrations/
└── routes/api.php
```

### Dashboard React
```
dashboard/
├── src/
│   ├── components/
│   │   └── layout/
│   │       ├── Sidebar.tsx
│   │       └── DashboardLayout.tsx
│   ├── pages/
│   │   ├── auth/LoginPage.tsx
│   │   ├── dashboard/DashboardPage.tsx
│   │   ├── restaurants/RestaurantsPage.tsx
│   │   └── orders/OrdersPage.tsx
│   ├── services/api.ts
│   ├── context/AuthContext.tsx
│   ├── types/index.ts
│   └── App.tsx
└── vite.config.ts
```

---

## 🔐 Sécurité

- Authentification via Laravel Sanctum (tokens API)
- Protection CSRF pour les requêtes stateful
- Validation des données côté serveur
- Hashage des mots de passe (Bcrypt)
- CORS configuré pour les domaines autorisés

---

## 🚢 Déploiement

### Production

1. **Backend Laravel**
   ```bash
   composer install --optimize-autoloader --no-dev
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

2. **Dashboard React**
   ```bash
   npm run build
   # Déployer le contenu du dossier dist/
   ```

3. **Flutter**
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

---

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 👨‍💻 Auteur

**DEVBACKEND** - Développeur Full Stack

---

*Documentation créée le 19 mars 2026*
