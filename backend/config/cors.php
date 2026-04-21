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
        env('FRONTEND_URL', 'https://noogo-app.netlify.app'),
        'https://noogo-app.netlify.app',
        'https://noogo.netlify.app',
        'https://noogo-dashboard.netlify.app',
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
