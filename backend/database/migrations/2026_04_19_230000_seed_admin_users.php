<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Hash;

return new class extends Migration {
    public function up(): void
    {
        // admin@noogo.com
        User::updateOrCreate(
            ['email' => 'admin@noogo.com'],
            [
                'name' => 'Admin Noogo',
                'password' => Hash::make('password123'),
                'phone' => '+226 70000000',
                'is_admin' => true,
                'role' => 'admin',
                'email_verified_at' => now(),
            ]
        );

        // super-user@noogo.com
        User::updateOrCreate(
            ['email' => 'super-user@noogo.com'],
            [
                'name' => 'Super User',
                'password' => Hash::make('password123'),
                'phone' => '+226 70000001',
                'is_admin' => true,
                'role' => 'super_admin',
                'email_verified_at' => now(),
            ]
        );

        // daniel@noogo.com
        User::updateOrCreate(
            ['email' => 'daniel@noogo.com'],
            [
                'name' => 'Daniel',
                'password' => Hash::make('password123'),
                'phone' => '+226 70000002',
                'is_admin' => true,
                'role' => 'admin',
                'email_verified_at' => now(),
            ]
        );
    }

    public function down(): void
    {
        User::whereIn('email', [
            'admin@noogo.com',
            'super-user@noogo.com',
            'daniel@noogo.com',
        ])->delete();
    }
};
