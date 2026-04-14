<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS)
    |--------------------------------------------------------------------------
    | Autorise le dashboard Netlify et l'app Flutter à appeler l'API Render.
    | Modifier FRONTEND_URL dans les variables d'environnement Render.
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        env('FRONTEND_URL', 'http://localhost:5173'),
        'http://localhost:5173',
        'http://localhost:3000',
        'http://localhost:8080',
    ],

    // Autorise uniquement le sous-domaine Netlify exact défini dans NETLIFY_SUBDOMAIN (ex: noogo-dashboard)
    // + tous les ports localhost pour le dev Flutter web
    'allowed_origins_patterns' => [
        '#^https://' . preg_quote(env('NETLIFY_SUBDOMAIN', 'noogo'), '#') . '\.netlify\.app$#',
        '#^http://localhost(:\d+)?$#',
        '#^http://127\.0\.0\.1(:\d+)?$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => true,

];
