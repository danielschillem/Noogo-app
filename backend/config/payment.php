<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Payment Gateway
    |--------------------------------------------------------------------------
    | simulation  → mode dev, OTP "1234" valide tout
    | cinetpay    → production, appelle l'API CinetPay
    */

    'gateway' => env('PAYMENT_GATEWAY', 'simulation'),

    // CinetPay
    'cinetpay_api_key' => env('CINETPAY_API_KEY', ''),
    'cinetpay_site_id' => env('CINETPAY_SITE_ID', ''),

    // Durée de validité d'un paiement (minutes)
    'payment_ttl_minutes' => (int) env('PAYMENT_TTL_MINUTES', 15),
];
