<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Restaurant;
use App\Models\Category;
use App\Models\Dish;
use App\Models\FlashInfo;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create admin user
        $admin = User::create([
            'name' => 'Admin Noogo',
            'email' => 'admin@noogo.com',
            'password' => Hash::make('password'),
            'phone' => '+226 70000000',
            'is_admin' => true,
            'email_verified_at' => now(),
        ]);

        // Create demo restaurant owner
        $owner = User::create([
            'name' => 'Restaurant Owner',
            'email' => 'owner@noogo.com',
            'password' => Hash::make('password'),
            'phone' => '+226 71111111',
            'is_admin' => false,
            'email_verified_at' => now(),
        ]);

        // Create demo restaurant
        $restaurant = Restaurant::create([
            'user_id' => $owner->id,
            'nom' => 'Le Gourmet Africain',
            'telephone' => '+226 72222222',
            'adresse' => 'Ouaga 2000, Ouagadougou',
            'email' => 'contact@legourmet.bf',
            'description' => 'Restaurant de cuisine africaine traditionnelle et moderne.',
            'heures_ouverture' => '08:00-22:00',
            'is_active' => true,
        ]);

        // Create categories
        $categories = [
            ['nom' => 'Entrées', 'description' => 'Pour bien commencer', 'ordre' => 1],
            ['nom' => 'Plats Principaux', 'description' => 'Nos spécialités', 'ordre' => 2],
            ['nom' => 'Accompagnements', 'description' => 'Pour accompagner vos plats', 'ordre' => 3],
            ['nom' => 'Boissons', 'description' => 'Boissons fraîches et chaudes', 'ordre' => 4],
            ['nom' => 'Desserts', 'description' => 'Pour terminer en douceur', 'ordre' => 5],
        ];

        foreach ($categories as $catData) {
            Category::create([
                'restaurant_id' => $restaurant->id,
                ...$catData,
            ]);
        }

        // Create dishes
        $dishes = [
            ['nom' => 'Salade Africaine', 'description' => 'Salade fraîche aux légumes locaux', 'prix' => 2500, 'category_id' => 1],
            ['nom' => 'Brochettes de Poulet', 'description' => 'Brochettes marinées aux épices', 'prix' => 3500, 'category_id' => 1],
            ['nom' => 'Poulet Braisé', 'description' => 'Poulet grillé aux herbes', 'prix' => 5000, 'category_id' => 2, 'is_plat_du_jour' => true],
            ['nom' => 'Poisson Braisé', 'description' => 'Poisson frais grillé', 'prix' => 6500, 'category_id' => 2],
            ['nom' => 'Garba', 'description' => 'Attiéké au thon frit', 'prix' => 2000, 'category_id' => 2, 'is_plat_du_jour' => true],
            ['nom' => 'Attiéké', 'description' => 'Semoule de manioc', 'prix' => 500, 'category_id' => 3],
            ['nom' => 'Alloco', 'description' => 'Bananes plantains frites', 'prix' => 1000, 'category_id' => 3],
            ['nom' => 'Bissap', 'description' => 'Jus d\'hibiscus frais', 'prix' => 500, 'category_id' => 4],
            ['nom' => 'Gingembre', 'description' => 'Jus de gingembre maison', 'prix' => 500, 'category_id' => 4],
            ['nom' => 'Banane Flambée', 'description' => 'Banane caramélisée', 'prix' => 2000, 'category_id' => 5],
        ];

        foreach ($dishes as $dishData) {
            Dish::create([
                'restaurant_id' => $restaurant->id,
                'temps_preparation' => rand(10, 30),
                'disponibilite' => true,
                ...$dishData,
            ]);
        }

        FlashInfo::create([
            'restaurant_id' => $restaurant->id,
            'titre' => 'Promo Week-end!',
            'description' => '-20% sur tous les plats principaux!',
            'type' => 'promotion',
            'reduction_percentage' => 20,
            'date_debut' => now(),
            'date_fin' => now()->addDays(7),
            'is_active' => true,
        ]);

        $this->command->info('✅ Database seeded! Admin: admin@noogo.com / password');
    }
}
