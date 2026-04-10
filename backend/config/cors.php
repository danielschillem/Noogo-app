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
    ],

    // Autorise tous les sous-domaines netlify.app (prévisualisation de déploiement)
    'allowed_origins_patterns' => [
        '#^https://[\w-]+\.netlify\.app$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => true,

];
