# ============================================================
# render-deploy.ps1 — Automatisation complète du déploiement
#                     Noogo sur Render via leur API REST
# ============================================================
# Usage :
#   1. Ouvrez PowerShell dans le dossier du projet
#   2. Lancez : .\render-deploy.ps1
#   3. Le script demande votre clé API Render (commence par rnd_)
#
# Render Dashboard → Account Settings → API Keys → Create API Key
# ============================================================

$ErrorActionPreference = "Stop"

# ── Couleurs ──────────────────────────────────────────────────
function Write-Info    { param($m) Write-Host "[INFO]  $m" -ForegroundColor Green }
function Write-Warn    { param($m) Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err     { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }
function Write-Step    { param($m) Write-Host "`n===== $m =====" -ForegroundColor Cyan }

# ── 0. Clé API ────────────────────────────────────────────────
Write-Step "Configuration"
$RENDER_API_KEY = Read-Host "Collez votre clé API Render (rnd_...)" -AsSecureString
$RENDER_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($RENDER_API_KEY)
)

if (-not $RENDER_API_KEY.StartsWith("rnd_")) {
    Write-Err "La clé API Render doit commencer par 'rnd_'"
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $RENDER_API_KEY"
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
}

$BASE = "https://api.render.com/v1"

# ── Fonction helper API ────────────────────────────────────────
function Invoke-Render {
    param($Method, $Path, $Body = $null)
    $uri = "$BASE$Path"
    try {
        if ($Body) {
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers `
                   -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json"
        } else {
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
        }
    } catch {
        Write-Err "API Render : $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            Write-Err $reader.ReadToEnd()
        }
        exit 1
    }
}

# ── ÉTAPE 1 : Récupérer la PostgreSQL existante ────────────────
Write-Step "Etape 1 : Récupération de la base de données PostgreSQL"

$postgres = Invoke-Render -Method GET -Path "/postgres?limit=20"
if ($postgres.Count -eq 0) {
    Write-Err "Aucune base PostgreSQL trouvée sur votre compte Render."
    exit 1
}

# Afficher les DBs disponibles si plusieurs
if ($postgres.Count -gt 1) {
    Write-Warn "Plusieurs bases trouvées :"
    for ($i = 0; $i -lt $postgres.Count; $i++) {
        $db = $postgres[$i].postgres
        Write-Host "  [$i] $($db.name) (id: $($db.id), status: $($db.status))"
    }
    $idx = Read-Host "Numéro de la base à utiliser"
    $selectedDb = $postgres[$idx].postgres
} else {
    $selectedDb = $postgres[0].postgres
}

Write-Info "Base sélectionnée : $($selectedDb.name) (id: $($selectedDb.id))"

# Récupérer la connection string interne
$dbInfo = Invoke-Render -Method GET -Path "/postgres/$($selectedDb.id)/connection-info"
$DB_URL  = $dbInfo.internalConnectionString

if (-not $DB_URL) {
    Write-Err "Impossible de récupérer la connection string interne."
    exit 1
}
Write-Info "DB_URL interne récupérée ✓"

# ── ÉTAPE 2 : Récupérer l'owner (compte) ──────────────────────
Write-Step "Etape 2 : Récupération du compte"
$owners = Invoke-Render -Method GET -Path "/owners?limit=1"
$ownerId = $owners[0].owner.id
Write-Info "Owner ID : $ownerId"

# ── ÉTAPE 3 : Créer le Web Service noogo-backend ──────────────
Write-Step "Etape 3 : Création du service web noogo-backend"

# Vérifier si le service existe déjà
$existingServices = Invoke-Render -Method GET -Path "/services?name=noogo-backend&limit=5"
$existingService = $existingServices | Where-Object { $_.service.name -eq "noogo-backend" } | Select-Object -First 1

if ($existingService) {
    $serviceId = $existingService.service.id
    Write-Warn "Service 'noogo-backend' existe déjà (id: $serviceId). Mise à jour des variables d'environnement..."
} else {
    Write-Info "Création du service Docker..."

    $serviceBody = @{
        type    = "web_service"
        name    = "noogo-backend"
        ownerId = $ownerId
        repo    = "https://github.com/danielschillem/Noogo-app"
        branch  = "develop"
        serviceDetails = @{
            runtime        = "docker"
            dockerfilePath = "./backend/Dockerfile"
            dockerContext  = "./backend"
            envSpecificDetails = @{
                dockerfilePath = "./backend/Dockerfile"
                dockerContext  = "./backend"
            }
            plan           = "free"
            region         = "frankfurt"
            healthCheckPath = "/up"
        }
    }

    $newService = Invoke-Render -Method POST -Path "/services" -Body $serviceBody
    $serviceId  = $newService.service.id
    Write-Info "Service créé ! ID : $serviceId"
    Write-Info "URL : https://noogo-backend.onrender.com"
    Start-Sleep -Seconds 3
}

# ── ÉTAPE 4 : Injecter les variables d'environnement ──────────
Write-Step "Etape 4 : Configuration des variables d'environnement"

# Générer une APP_KEY Laravel valide (base64:...)
$keyBytes  = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Fill($keyBytes)
$APP_KEY   = "base64:" + [Convert]::ToBase64String($keyBytes)

$envVars = @(
    @{ key = "APP_NAME";               value = "Noogo" }
    @{ key = "APP_ENV";                value = "production" }
    @{ key = "APP_DEBUG";              value = "false" }
    @{ key = "APP_KEY";                value = $APP_KEY }
    @{ key = "APP_URL";                value = "https://noogo-backend.onrender.com" }
    @{ key = "DB_CONNECTION";          value = "pgsql" }
    @{ key = "DB_URL";                 value = $DB_URL }
    @{ key = "SESSION_DRIVER";         value = "cookie" }
    @{ key = "CACHE_STORE";            value = "file" }
    @{ key = "FILESYSTEM_DISK";        value = "public" }
    @{ key = "LOG_CHANNEL";            value = "stderr" }
    @{ key = "LOG_LEVEL";              value = "error" }
    @{ key = "SANCTUM_STATEFUL_DOMAINS"; value = "noogo-dashboard.netlify.app" }
    @{ key = "FRONTEND_URL";           value = "https://noogo-dashboard.netlify.app" }
    @{ key = "BROADCAST_CONNECTION";   value = "pusher" }
    @{ key = "PUSHER_APP_CLUSTER";     value = "eu" }
)

# Pusher optionnel
$pusherAppId  = Read-Host "PUSHER_APP_ID (Entrée pour ignorer)"
$pusherKey    = Read-Host "PUSHER_APP_KEY (Entrée pour ignorer)"
$pusherSecret = Read-Host "PUSHER_APP_SECRET (Entrée pour ignorer)"

if ($pusherAppId)  { $envVars += @{ key = "PUSHER_APP_ID";     value = $pusherAppId } }
if ($pusherKey)    { $envVars += @{ key = "PUSHER_APP_KEY";    value = $pusherKey } }
if ($pusherSecret) { $envVars += @{ key = "PUSHER_APP_SECRET"; value = $pusherSecret } }

$result = Invoke-Render -Method PUT -Path "/services/$serviceId/env-vars" -Body $envVars

Write-Info "$($result.Count) variables d'environnement configurées ✓"

# ── ÉTAPE 5 : Déclencher le déploiement ───────────────────────
Write-Step "Etape 5 : Déclenchement du déploiement"

$deploy = Invoke-Render -Method POST -Path "/services/$serviceId/deploys" -Body @{ clearCache = "do_not_clear" }
$deployId = $deploy.deploy.id

Write-Info "Déploiement lancé ! ID : $deployId"
Write-Info "Suivez les logs sur : https://dashboard.render.com/web/$serviceId/deploys/$deployId"

# ── Résumé final ──────────────────────────────────────────────
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host " DÉPLOIEMENT LANCÉ AVEC SUCCÈS" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Service ID : $serviceId"
Write-Host " Deploy  ID : $deployId"
Write-Host " URL API    : https://noogo-backend.onrender.com"
Write-Host " Logs       : https://dashboard.render.com/web/$serviceId"
Write-Host ""
Write-Host " Prochaine étape : déployer le dashboard sur Netlify" -ForegroundColor Yellow
Write-Host "   → VITE_API_URL = https://noogo-backend.onrender.com/api"
Write-Host "============================================" -ForegroundColor Cyan
