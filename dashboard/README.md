# 📊 Noogo Dashboard

> Interface d'administration React pour la plateforme de restauration Noogo

---

## 📋 Informations

| Champ | Valeur |
|-------|--------|
| **Version** | 1.0.0 |
| **Date** | Mars 2026 |
| **Dernière mise à jour** | Janvier 2026 |
| **Développeur** | QUICK DEV-IT |
| **Framework** | React 18 + Vite + TypeScript |
| **Licence** | Propriétaire |
| **Copyright** | © 2026 QUICK DEV-IT |

---

## 🚀 Installation

```bash
# Installer les dépendances
npm install

# Démarrer en développement
npm run dev

# Build de production
npm run build
```

---

## 🔧 Configuration

Créer un fichier `.env` :

```env
VITE_API_URL=http://localhost:8000/api
```

---

## 📁 Structure

```
src/
├── components/     # Composants réutilisables
├── pages/          # Pages de l'application
├── services/       # Services API
├── context/        # Contextes React
├── hooks/          # Hooks personnalisés
└── types/          # Types TypeScript
```

---

## 🎨 Technologies

- **React 18** - Framework UI
- **TypeScript** - Typage statique
- **Vite** - Build tool
- **TailwindCSS** - Styles
- **React Router** - Navigation
- **React Query** - Gestion d'état serveur
- **Recharts** - Graphiques
- **Lucide React** - Icônes
      tseslint.configs.stylisticTypeChecked,

      // Other configs...
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...
      // Enable lint rules for React
      reactX.configs['recommended-typescript'],
      // Enable lint rules for React DOM
      reactDom.configs.recommended,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```
