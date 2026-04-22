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

    'allowed_origins' => [
        env('FRONTEND_URL', 'https://dashboard-noogo.quickdev-it.com'),
        'https://dashboard-noogo.quickdev-it.com',
        'http://localhost:5173',
        'http://localhost:3000',
        'http://localhost:8080',
    ],

    'allowed_origins_patterns' => [
        '/^http:\/\/localhost(:\d+)?$/',
        '/^http:\/\/127\.0\.0\.1(:\d+)?$/',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => true,

];
