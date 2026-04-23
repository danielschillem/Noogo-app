<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS)
    |--------------------------------------------------------------------------
    | Autorise le dashboard et l'app Flutter à appeler l'API Digital Ocean.
    | Modifier FRONTEND_URL dans les variables d'environnement.
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_filter([
        env('FRONTEND_URL', 'https://dashboard-noogo.quickdev-it.com'),
        'https://dashboard-noogo.quickdev-it.com',
        // localhost uniquement en développement local
        app()->environment('local', 'testing') ? 'http://localhost:5173' : null,
        app()->environment('local', 'testing') ? 'http://localhost:3000' : null,
        app()->environment('local', 'testing') ? 'http://localhost:8080' : null,
    ]),

    'allowed_origins_patterns' => app()->environment('local', 'testing') ? [
        '/^http:\/\/localhost(:\d+)?$/',
        '/^http:\/\/127\.0\.0\.1(:\d+)?$/',
    ] : [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => true,

];
