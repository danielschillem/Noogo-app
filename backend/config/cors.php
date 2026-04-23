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
        env('FRONTEND_URL', 'https://noogo-e5ygx.ondigitalocean.app'),
        env('APP_URL'),
        'https://noogo-e5ygx.ondigitalocean.app',
        // localhost uniquement en développement local
        in_array(env('APP_ENV', 'production'), ['local', 'testing'], true) ? 'http://localhost:5173' : null,
        in_array(env('APP_ENV', 'production'), ['local', 'testing'], true) ? 'http://localhost:3000' : null,
        in_array(env('APP_ENV', 'production'), ['local', 'testing'], true) ? 'http://localhost:8080' : null,
    ]),

    'allowed_origins_patterns' => in_array(env('APP_ENV', 'production'), ['local', 'testing'], true) ? [
        '/^http:\/\/localhost(:\d+)?$/',
        '/^http:\/\/127\.0\.0\.1(:\d+)?$/',
    ] : [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 86400,

    'supports_credentials' => true,

];
