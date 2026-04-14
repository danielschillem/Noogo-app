import '../models/restaurant.dart';
import '../models/category.dart';
import '../models/dish.dart';
import '../models/flash_info.dart';

/// Données de démonstration statiques — utilisées uniquement en mode debug
/// pour prévisualiser les écrans sans backend.
class DemoData {
  static Restaurant get restaurant => Restaurant(
        id: 1,
        nom: 'Le Jardin Gourmand',
        telephone: '+221 77 123 45 67',
        adresse: '12 Avenue Cheikh Anta Diop, Dakar',
        email: 'contact@jardin-gourmand.sn',
        logo:
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&q=80',
        description:
            'Restaurant africain moderne proposant une cuisine sénégalaise revisitée dans un cadre chaleureux et contemporain.',
        heuresOuverture: '08:00-23:00',
        images: [
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80',
          'https://images.unsplash.com/photo-1544148103-0773bf10d330?w=800&q=80',
        ],
        isOpenFromApi: true,
        latitude: 14.6928,
        longitude: -17.4461,
      );

  static List<Category> get categories => [
        Category(
          id: 1,
          name: 'Entrées',
          imageUrl:
              'https://images.unsplash.com/photo-1541014741259-de529411b96a?w=200&q=80',
        ),
        Category(
          id: 2,
          name: 'Grillades',
          imageUrl:
              'https://images.unsplash.com/photo-1544025162-d76694265947?w=200&q=80',
        ),
        Category(
          id: 3,
          name: 'Poissons',
          imageUrl:
              'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=200&q=80',
        ),
        Category(
          id: 4,
          name: 'Desserts',
          imageUrl:
              'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=200&q=80',
        ),
        Category(
          id: 5,
          name: 'Boissons',
          imageUrl:
              'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200&q=80',
        ),
        Category(
          id: 6,
          name: 'Plats du jour',
          imageUrl:
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200&q=80',
        ),
      ];

  static List<Dish> get dishes => [
        Dish(
          id: 1,
          name: 'Thiéboudienne Royal',
          description:
              'Le plat national sénégalais revisité : riz au poisson avec légumes frais, sauce tomate maison et poisson de mer grillé.',
          price: 4500,
          imageUrl:
              'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&q=80',
          categoryId: 3,
          category: 'Poissons',
          isAvailable: true,
          isDishOfTheDay: true,
          preparationTime: 30,
        ),
        Dish(
          id: 2,
          name: 'Poulet Yassa',
          description:
              'Poulet mariné à l\'oignon et au citron, mijoté lentement avec des olives et servi avec du riz blanc.',
          price: 3800,
          imageUrl:
              'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&q=80',
          categoryId: 2,
          category: 'Grillades',
          isAvailable: true,
          preparationTime: 25,
        ),
        Dish(
          id: 3,
          name: 'Mafé Bœuf',
          description:
              'Ragoût de bœuf à la sauce d\'arachide, avec pommes de terre et carottes. Un classique de la cuisine ouest-africaine.',
          price: 4200,
          imageUrl:
              'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&q=80',
          categoryId: 2,
          category: 'Grillades',
          isAvailable: true,
          preparationTime: 35,
        ),
        Dish(
          id: 4,
          name: 'Salade Exotique',
          description:
              'Salade fraîche aux fruits tropicaux, avocat, mangue, crevettes et vinaigrette au gingembre.',
          price: 2500,
          imageUrl:
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
          categoryId: 1,
          category: 'Entrées',
          isAvailable: true,
          preparationTime: 10,
        ),
        Dish(
          id: 5,
          name: 'Brochettes Mixtes',
          description:
              'Assortiment de brochettes : bœuf mariné, poulet épicé et légumes grillés. Servies avec sauce piment maison.',
          price: 5500,
          imageUrl:
              'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600&q=80',
          categoryId: 2,
          category: 'Grillades',
          isAvailable: true,
          preparationTime: 20,
        ),
        Dish(
          id: 6,
          name: 'Jus de Bissap',
          description:
              'Jus d\'hibiscus traditionnel, légèrement sucré avec une touche de menthe fraîche. Servi frais.',
          price: 800,
          imageUrl:
              'https://images.unsplash.com/photo-1546173159-315724a31696?w=600&q=80',
          categoryId: 5,
          category: 'Boissons',
          isAvailable: true,
          preparationTime: 5,
        ),
        Dish(
          id: 7,
          name: 'Mousse Mangue',
          description:
              'Mousse légère à la mangue fraîche, coulis de fruits de la passion et tuile coco.',
          price: 1800,
          imageUrl:
              'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&q=80',
          categoryId: 4,
          category: 'Desserts',
          isAvailable: true,
          preparationTime: 5,
        ),
        Dish(
          id: 8,
          name: 'Crevettes Grillées',
          description:
              'Crevettes royales marinées à l\'ail et au citron, grillées et servies avec riz parfumé.',
          price: 6500,
          imageUrl:
              'https://images.unsplash.com/photo-1556269923-e4ef51d69638?w=600&q=80',
          categoryId: 3,
          category: 'Poissons',
          isAvailable: false,
          preparationTime: 20,
        ),
      ];

  static List<FlashInfo> get flashInfos => [
        FlashInfo(
          id: 1,
          name: 'Offre du jour — 20% de réduction',
          description:
              'Ce midi uniquement : 20% de réduction sur tous les plats du jour. Profitez-en !',
          validityPeriod: 'Aujourd\'hui seulement, jusqu\'à 15h',
          discountType: 'percentage',
          discountValue: '20',
          imageUrl:
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
          backgroundColor: '#FF6B35',
          buttonText: 'Commander maintenant',
        ),
        FlashInfo(
          id: 2,
          name: 'Menu Duo à 6 000 FCFA',
          description:
              '2 plats + 2 boissons + 1 dessert partagé. Idéal pour un déjeuner en duo.',
          validityPeriod: 'Valable du lundi au vendredi',
          imageUrl:
              'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
          backgroundColor: '#00AD48',
          buttonText: 'Voir le menu duo',
        ),
      ];
}
