<?php

namespace Database\Seeders;

use App\Models\DeliveryDriver;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUsersSeeder extends Seeder
{
    public function run(): void
    {
        // Super User
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

        // Admin
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

        // Livreur de test
        $livreurUser = User::updateOrCreate(
            ['phone' => '+22670000010'],
            [
                'name' => 'Livreur Test',
                'email' => 'livreur@noogo.com',
                'password' => Hash::make('password123'),
                'is_admin' => false,
                // users.role accepts only user/admin/super_admin in current schema.
                'role' => 'user',
                'email_verified_at' => now(),
            ]
        );

        DeliveryDriver::updateOrCreate(
            ['user_id' => $livreurUser->id],
            [
                'name' => 'Livreur Test',
                'phone' => '+22670000010',
                'zone' => 'Ouagadougou',
                'status' => 'offline',
            ]
        );

        $this->command->info('✓ super-user@noogo.com (super_admin) créé/mis à jour');
        $this->command->info('✓ daniel@noogo.com (admin) créé/mis à jour');
        $this->command->info('✓ livreur@noogo.com / +22670000010 (driver) créé/mis à jour');
    }
}
