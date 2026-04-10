# ============================================================
# render-deploy.ps1 — Deploiement Noogo sur Render via API
# ============================================================
# ETAPE UNIQUE : remplacez la valeur ci-dessous et lancez :
#   .\render-deploy.ps1
#
# Cle API : render.com -> icone compte -> Account Settings
#           -> API Keys -> Create API Key
# ============================================================
$RENDER_API_KEY    = "rnd_COLLEZ_VOTRE_CLE_ICI"
$PUSHER_APP_ID     = ""   # Optionnel
$PUSHER_APP_KEY    = ""   # Optionnel
$PUSHER_APP_SECRET = ""   # Optionnel
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Info { param($m) Write-Host "[INFO]  $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Step { param($m) Write-Host "`n===== $m =====" -ForegroundColor Cyan }
function Write-Fail { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red; exit 1 }

if ($RENDER_API_KEY -eq "rnd_COLLEZ_VOTRE_CLE_ICI") {
    Write-Fail "Ouvrez render-deploy.ps1 et remplacez 'rnd_COLLEZ_VOTRE_CLE_ICI' par votre cle API Render."
}
if (-not $RENDER_API_KEY.StartsWith("rnd_")) {
    Write-Fail "La cle API Render doit commencer par rnd_"
}

Write-Step "Deploiement Noogo sur Render"
Write-Info "Cle API detectee OK"

$hdrs = @{ Authorization = "Bearer $RENDER_API_KEY"; Accept = "application/json" }
$BASE = "https://api.render.com/v1"

function CallApi {
    param([string]$method, [string]$path, $body = $null)
    $uri = $BASE + $path
    if ($body) {
        $json = $body | ConvertTo-Json -Depth 10
        return Invoke-RestMethod -Method $method -Uri $uri -Headers $hdrs -Body $json -ContentType "application/json"
    }
    return Invoke-RestMethod -Method $method -Uri $uri -Headers $hdrs
}

Write-Step "Etape 1 : Base PostgreSQL"
$pgList = CallApi GET "/postgres?limit=20"
if ($pgList.Count -eq 0) { Write-Fail "Aucune base PostgreSQL trouvee." }
$pgDb = $pgList[0].postgres
Write-Info "Base : $($pgDb.name)"
$connInfo = CallApi GET "/postgres/$($pgDb.id)/connection-info"
$DB_URL = $connInfo.internalConnectionString
if (-not $DB_URL) { Write-Fail "Connection string introuvable." }
Write-Info "DB_URL OK"

Write-Step "Etape 2 : Compte Render"
$owners = CallApi GET "/owners?limit=1"
$ownerId = $owners[0].owner.id
Write-Info "Owner : $ownerId"

Write-Step "Etape 3 : Service noogo-backend"
$svcList = CallApi GET "/services?limit=20"
$existing = $svcList | Where-Object { $_.service.name -eq "noogo-backend" } | Select-Object -First 1

if ($existing) {
    $serviceId = $existing.service.id
    Write-Warn "Service existant (id: $serviceId), mise a jour env vars."
} else {
    Write-Info "Creation du service..."
    $body = @{
        type    = "web_service"
        name    = "noogo-backend"
        ownerId = $ownerId
        repo    = "https://github.com/danielschillem/Noogo-app"
        branch  = "develop"
        serviceDetails = @{
            runtime         = "docker"
            dockerfilePath  = "./backend/Dockerfile"
            dockerContext   = "./backend"
            plan            = "free"
            region          = "frankfurt"
            healthCheckPath = "/up"
        }
    }
    $created = CallApi POST "/services" $body
    $serviceId = $created.service.id
    Write-Info "Service cree : $serviceId"
    Start-Sleep -Seconds 2
}

Write-Step "Etape 4 : Variables d'environnement"
$keyBytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Fill($keyBytes)
$APP_KEY = "base64:" + [Convert]::ToBase64String($keyBytes)

$envVars = @(
    @{ key = "APP_NAME";                 value = "Noogo" }
    @{ key = "APP_ENV";                  value = "production" }
    @{ key = "APP_DEBUG";                value = "false" }
    @{ key = "APP_KEY";                  value = $APP_KEY }
    @{ key = "APP_URL";                  value = "https://noogo-backend.onrender.com" }
    @{ key = "DB_CONNECTION";            value = "pgsql" }
    @{ key = "DB_URL";                   value = $DB_URL }
    @{ key = "SESSION_DRIVER";           value = "cookie" }
    @{ key = "CACHE_STORE";              value = "file" }
    @{ key = "FILESYSTEM_DISK";          value = "public" }
    @{ key = "LOG_CHANNEL";              value = "stderr" }
    @{ key = "LOG_LEVEL";               value = "error" }
    @{ key = "SANCTUM_STATEFUL_DOMAINS"; value = "noogo-dashboard.netlify.app" }
    @{ key = "FRONTEND_URL";             value = "https://noogo-dashboard.netlify.app" }
    @{ key = "BROADCAST_CONNECTION";     value = "pusher" }
    @{ key = "PUSHER_APP_CLUSTER";       value = "eu" }
)
if ($PUSHER_APP_ID)     { $envVars += @{ key = "PUSHER_APP_ID";     value = $PUSHER_APP_ID } }
if ($PUSHER_APP_KEY)    { $envVars += @{ key = "PUSHER_APP_KEY";    value = $PUSHER_APP_KEY } }
if ($PUSHER_APP_SECRET) { $envVars += @{ key = "PUSHER_APP_SECRET"; value = $PUSHER_APP_SECRET } }

CallApi PUT "/services/$serviceId/env-vars" $envVars | Out-Null
Write-Info "$($envVars.Count) variables configurees OK"

Write-Step "Etape 5 : Lancement du deploiement"
$deplBody = @{ clearCache = "do_not_clear" }
$deploy = CallApi POST "/services/$serviceId/deploys" $deplBody
$deployId = $deploy.deploy.id
Write-Info "Deploiement lance ! ID : $deployId"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SUCCES !" -ForegroundColor Green
Write-Host " URL API : https://noogo-backend.onrender.com"
Write-Host " Logs    : https://dashboard.render.com/web/$serviceId"
Write-Host ""
Write-Host " Etape suivante Netlify :" -ForegroundColor Yellow
Write-Host "   VITE_API_URL = https://noogo-backend.onrender.com/api"
Write-Host "============================================" -ForegroundColor Cyan
