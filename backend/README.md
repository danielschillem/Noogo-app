# 🖥️ Noogo Backend API

> API RESTful Laravel pour la plateforme de restauration Noogo

---

## 📋 Informations

| Champ | Valeur |
|-------|--------|
| **Version** | 1.0.0 |
| **Date** | Mars 2026 |
| **Dernière mise à jour** | Janvier 2026 |
| **Développeur** | QUICK DEV-IT |
| **Framework** | Laravel 11 |
| **Licence** | Propriétaire |
| **Copyright** | © 2026 QUICK DEV-IT |

---

## 🚀 Installation

```bash
# Installer les dépendances
composer install

# Configurer l'environnement
cp .env.example .env
php artisan key:generate

# Base de données SQLite
touch database/database.sqlite
php artisan migrate --seed

# Storage link
php artisan storage:link

# Démarrer le serveur
php artisan serve
```

---

## 🔐 Identifiants Demo

| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Admin | admin@noogo.com | password |
| Propriétaire | owner@noogo.com | password |

---

## 📡 Endpoints Principaux

- `POST /api/auth/login` - Connexion
- `GET /api/restaurants` - Liste restaurants
- `GET /api/restaurant/{id}/menu` - Menu complet
- `GET /api/restaurants/{id}/orders` - Commandes
- `GET /api/offres/actives/{id}` - Promotions

## Agentic Development

Laravel's predictable structure and conventions make it ideal for AI coding agents like Claude Code, Cursor, and GitHub Copilot. Install [Laravel Boost](https://laravel.com/docs/ai) to supercharge your AI workflow:

```bash
composer require laravel/boost --dev

php artisan boost:install
```

Boost provides your agent 15+ tools and skills that help agents build Laravel applications while following best practices.

## Contributing

Thank you for considering contributing to the Laravel framework! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
