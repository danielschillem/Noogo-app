<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Restaurant;
use App\Models\Category;
use App\Models\Dish;

class NoogoDeliceMenuSeeder extends Seeder
{
    /**
     * Seed demo menu for Noogo Delice (restaurant id=1) if it has no dishes.
     */
    public function run(): void
    {
        $restaurant = Restaurant::find(1);

        if (!$restaurant) {
            $this->command?->warn('Restaurant id=1 introuvable — seeder ignoré.');
            return;
        }

        // Skip if restaurant already has dishes
        if ($restaurant->dishes()->exists()) {
            $this->command?->info('Restaurant "' . $restaurant->nom . '" a déjà des plats — seeder ignoré.');
            return;
        }

        $this->command?->info('Ajout du menu démo pour "' . $restaurant->nom . '"...');

        // Create categories
        $categories = [
            ['nom' => 'Entrées', 'description' => 'Pour bien commencer', 'ordre' => 1],
            ['nom' => 'Plats Principaux', 'description' => 'Nos spécialités', 'ordre' => 2],
            ['nom' => 'Accompagnements', 'description' => 'Pour accompagner vos plats', 'ordre' => 3],
            ['nom' => 'Boissons', 'description' => 'Boissons fraîches et chaudes', 'ordre' => 4],
            ['nom' => 'Desserts', 'description' => 'Pour terminer en douceur', 'ordre' => 5],
        ];

        $categoryIds = [];
        foreach ($categories as $catData) {
            $cat = Category::firstOrCreate(
                ['restaurant_id' => $restaurant->id, 'nom' => $catData['nom']],
                [...$catData, 'restaurant_id' => $restaurant->id, 'is_active' => true]
            );
            $categoryIds[$catData['nom']] = $cat->id;
        }

        // Create dishes
        $dishes = [
            ['nom' => 'Salade Africaine', 'description' => 'Salade fraîche aux légumes locaux', 'prix' => 2500, 'cat' => 'Entrées'],
            ['nom' => 'Brochettes de Poulet', 'description' => 'Brochettes marinées aux épices', 'prix' => 3500, 'cat' => 'Entrées'],
            ['nom' => 'Poulet Braisé', 'description' => 'Poulet grillé aux herbes', 'prix' => 5000, 'cat' => 'Plats Principaux', 'is_plat_du_jour' => true],
            ['nom' => 'Poisson Braisé', 'description' => 'Poisson frais grillé', 'prix' => 6500, 'cat' => 'Plats Principaux'],
            ['nom' => 'Garba', 'description' => 'Attiéké au thon frit', 'prix' => 2000, 'cat' => 'Plats Principaux', 'is_plat_du_jour' => true],
            ['nom' => 'Riz au gras', 'description' => 'Riz cuisiné aux légumes et viande', 'prix' => 3000, 'cat' => 'Plats Principaux'],
            ['nom' => 'Attiéké', 'description' => 'Semoule de manioc', 'prix' => 500, 'cat' => 'Accompagnements'],
            ['nom' => 'Alloco', 'description' => 'Bananes plantains frites', 'prix' => 1000, 'cat' => 'Accompagnements'],
            ['nom' => 'Frites', 'description' => 'Frites de pommes de terre', 'prix' => 800, 'cat' => 'Accompagnements'],
            ['nom' => 'Bissap', 'description' => "Jus d'hibiscus frais", 'prix' => 500, 'cat' => 'Boissons'],
            ['nom' => 'Gingembre', 'description' => 'Jus de gingembre maison', 'prix' => 500, 'cat' => 'Boissons'],
            ['nom' => 'Eau minérale', 'description' => 'Bouteille 1.5L', 'prix' => 500, 'cat' => 'Boissons'],
            ['nom' => 'Banane Flambée', 'description' => 'Banane caramélisée', 'prix' => 2000, 'cat' => 'Desserts'],
            ['nom' => 'Dêguê', 'description' => 'Yaourt au mil', 'prix' => 1000, 'cat' => 'Desserts'],
        ];

        foreach ($dishes as $dishData) {
            $catName = $dishData['cat'];
            unset($dishData['cat']);

            Dish::create([
                'restaurant_id' => $restaurant->id,
                'category_id' => $categoryIds[$catName],
                'temps_preparation' => rand(10, 30),
                'disponibilite' => true,
                ...$dishData,
            ]);
        }

        $this->command?->info('✅ ' . count($dishes) . ' plats démo ajoutés à "' . $restaurant->nom . '"');
    }
}
