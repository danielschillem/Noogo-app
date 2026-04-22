#!/bin/bash
# ============================================================
# build_release.sh — Génère l'AAB signé pour le Play Store
# ============================================================
# Prérequis :
#   1. android/key.properties renseigné (noogo-release.jks)
#   2. assets/env/.env avec API_BASE_URL pointant sur DigitalOcean
#   3. Flutter SDK installé
# Usage : chmod +x build_release.sh && ./build_release.sh
# ============================================================

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── 1. Vérifications préalables ──────────────────────────────
if [ ! -f "android/key.properties" ]; then
    error "android/key.properties manquant ! Copiez key.properties.example et renseignez les valeurs."
fi

if [ ! -f "assets/env/.env" ]; then
    error "assets/env/.env manquant ! Créez ce fichier avec API_BASE_URL=https://noogo-e5ygx.ondigitalocean.app/api (URL DigitalOcean production)"
fi

API_URL=$(grep "API_BASE_URL" assets/env/.env | cut -d '=' -f2)
if echo "$API_URL" | grep -q "localhost"; then
    error "API_BASE_URL pointe encore sur localhost ! Mettez l'URL DigitalOcean de production."
fi

info "API URL : $API_URL"

# ── 2. Nettoyage ─────────────────────────────────────────────
info "Nettoyage du projet..."
flutter clean

# ── 3. Dépendances ───────────────────────────────────────────
info "Récupération des dépendances..."
flutter pub get

# ── 4. Build AAB (Android App Bundle) ────────────────────────
info "Build de l'AAB release (peut prendre 3-5 minutes)..."
flutter build appbundle --release

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$AAB_PATH" ]; then
    SIZE=$(du -sh "$AAB_PATH" | cut -f1)
    info "✅ AAB généré avec succès !"
    info "   Chemin : $AAB_PATH"
    info "   Taille : $SIZE"
    info ""
    info "Prochaines étapes Play Store :"
    info "  1. Connectez-vous sur https://play.google.com/console"
    info "  2. Créez une nouvelle application (com.quickdevit.noogo)"
    info "  3. Allez dans Production → Releases → Create new release"
    info "  4. Uploadez $AAB_PATH"
    info "  5. Renseignez les métadonnées (description, captures, etc.)"
    info "  6. Soumettez pour review (3-7 jours Google)"
else
    error "AAB non trouvé à $AAB_PATH. Vérifiez les erreurs de build ci-dessus."
fi
