enum MenuCategory {
  sandwiches(
    'Sandwiches',
    '🥪',
    'Burgers gourmets, tacos savoureux, club-sandwiches & paninis',
    'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=1200&q=80',
  ),
  plates(
    'Plats / Plates',
    '🍲',
    'Plats mijotés maison, viandes grillées, poissons nobles & pâtes',
    'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80',
  ),
  coffee(
    'Café',
    '☕',
    'Espressos grands crus d\'Éthiopie, cappuccinos & macchiatos glacés',
    'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=1200&q=80',
  ),
  drinks(
    'Boissons / Drinks',
    '🥤',
    'Cocktails sans alcool, jus pressés minute & smoothies vitaminés',
    'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=1200&q=80',
  ),
  desserts(
    'Desserts',
    '🍰',
    'Tiramisu maison, gâteaux coulants, tartes & crêpes fondantes',
    'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=1200&q=80',
  );

  final String label;
  final String emoji;
  final String subtitle;
  final String bannerImageUrl;

  const MenuCategory(
    this.label,
    this.emoji,
    this.subtitle,
    this.bannerImageUrl,
  );
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final bool isPopular;
  final bool isVegetarian;
  final String prepTime;
  final int calories;
  final List<String> ingredients;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.rating = 4.5,
    this.reviewsCount = 20,
    this.isPopular = false,
    this.isVegetarian = false,
    this.prepTime = '15-20 min',
    this.calories = 450,
    this.ingredients = const [],
  });

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    MenuCategory? category,
    String? imageUrl,
    double? rating,
    int? reviewsCount,
    bool? isPopular,
    bool? isVegetarian,
    String? prepTime,
    int? calories,
    List<String>? ingredients,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isPopular: isPopular ?? this.isPopular,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      prepTime: prepTime ?? this.prepTime,
      calories: calories ?? this.calories,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'isPopular': isPopular,
      'isVegetarian': isVegetarian,
      'prepTime': prepTime,
      'calories': calories,
      'ingredients': ingredients,
    };
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: MenuCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => MenuCategory.sandwiches,
      ),
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      isPopular: json['isPopular'] as bool? ?? false,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      prepTime: json['prepTime'] as String? ?? '15 min',
      calories: json['calories'] as int? ?? 400,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Sample catalog menu items covering all 5 categories
const List<MenuItemModel> sampleMenuItems = [
  // --- SANDWICHES / FAST-FOOD ---
  MenuItemModel(
    id: 'sw_1',
    name: 'Burger Double Smash Black Angus',
    description:
        'Deux steaks de bœuf Angus smashés, cheddar fondant affiné, oignons caramélisés, cornichons croquants et sauce signature sur pain brioché toasté.',
    price: 11.50,
    category: MenuCategory.sandwiches,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 142,
    isPopular: true,
    prepTime: '10-15 min',
    calories: 780,
    ingredients: [
      'Bœuf Angus 100%',
      'Pain brioché',
      'Cheddar affiné',
      'Oignons confits',
      'Sauce maison'
    ],
  ),
  MenuItemModel(
    id: 'sw_2',
    name: 'Club Sandwich Poulet Grillé & Avocat',
    description:
        'Triple étage de pain de mie doré, blanc de poulet rôti mariné aux herbes, avocat frais tranché, tomates mûres, œuf dur et mayonnaise légère.',
    price: 8.90,
    category: MenuCategory.sandwiches,
    imageUrl:
        'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=800&q=80',
    rating: 4.8,
    reviewsCount: 88,
    isPopular: true,
    prepTime: '8-10 min',
    calories: 560,
    ingredients: [
      'Pain complet grillé',
      'Poulet fermier mariné',
      'Avocat frais',
      'Tomates',
      'Mayonnaise ciboulette'
    ],
  ),
  MenuItemModel(
    id: 'sw_3',
    name: 'Tacos Français Double Viande & Fromagère',
    description:
        'Galette dorée garnie de tenders croustillants et viande hachée épicée, frites croustillantes à l\'intérieur et nappe de sauce fromagère secrète.',
    price: 9.50,
    category: MenuCategory.sandwiches,
    imageUrl:
        'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=800&q=80',
    rating: 4.7,
    reviewsCount: 95,
    prepTime: '12 min',
    calories: 820,
    ingredients: [
      'Tenders panés',
      'Viande hachée épicée',
      'Sauce fromagère maison',
      'Frites',
      'Sauce algérienne'
    ],
  ),
  MenuItemModel(
    id: 'sw_4',
    name: 'Panini Gourmand Mozzarella, Pesto & Tomate',
    description:
        'Pain ciabatta artisanal toasté et strié, mozzarella fior di latte fondante, pesto génois au basilic frais et tomates confites au soleil.',
    price: 7.20,
    category: MenuCategory.sandwiches,
    imageUrl:
        'https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=800&q=80',
    rating: 4.6,
    reviewsCount: 62,
    isVegetarian: true,
    prepTime: '7 min',
    calories: 490,
    ingredients: [
      'Pain Ciabatta',
      'Mozzarella fondante',
      'Pesto au basilic DOP',
      'Tomates séchées'
    ],
  ),

  // --- PLATS (PLATES) ---
  MenuItemModel(
    id: 'pl_1',
    name: 'Pavé de Saumon Rôti & Légumes Croquants',
    description:
        'Pavé de saumon frais poêlé à la perfection, purée maison onctueuse à l\'ail doux, asperges et carottes glacées avec émulsion citronnée.',
    price: 15.90,
    category: MenuCategory.plates,
    imageUrl:
        'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 110,
    isPopular: true,
    prepTime: '20-25 min',
    calories: 520,
    ingredients: [
      'Saumon Atlantique',
      'Pommes de terre grenailles',
      'Asperges vertes',
      'Beurre blanc citronné'
    ],
  ),
  MenuItemModel(
    id: 'pl_2',
    name: 'Couscous Royal Traditionnel',
    description:
        'Semoule fine cuite à la vapeur, mijoté de légumes fondants, agneau tendre confit, poulet fermier rôti et merguez artisanale aux épices.',
    price: 16.50,
    category: MenuCategory.plates,
    imageUrl:
        'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 88,
    isPopular: true,
    prepTime: '25-30 min',
    calories: 790,
    ingredients: [
      'Semoule fine de blé dur',
      'Agneau mijoté',
      'Poulet fermier',
      'Pois chiches',
      'Courgettes',
      'Carottes'
    ],
  ),
  MenuItemModel(
    id: 'pl_3',
    name: 'Tagliatelles Fraîches aux Truffes & Parmesan',
    description:
        'Pâtes fraîches maison enrobées d\'une crème onctueuse de parmesan Reggiano 24 mois, brisures de truffe d\'été et poivre noir concassé.',
    price: 14.80,
    category: MenuCategory.plates,
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3d5d6281788?auto=format&fit=crop&w=800&q=80',
    rating: 4.8,
    reviewsCount: 65,
    isVegetarian: true,
    prepTime: '15-18 min',
    calories: 580,
    ingredients: [
      'Pâtes fraîches aux œufs',
      'Crème de truffe',
      'Parmigiano Reggiano',
      'Poivre noir moulu'
    ],
  ),
  MenuItemModel(
    id: 'pl_4',
    name: 'Entrecôte Grillée Sauce Poivre Vert',
    description:
        'Pièce de bœuf tendre 250g saisie sur grill au feu de bois, frites maison croustillantes et sauce crémeuse au poivre vert de Madagascar.',
    price: 17.50,
    category: MenuCategory.plates,
    imageUrl:
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
    rating: 4.7,
    reviewsCount: 92,
    prepTime: '20 min',
    calories: 820,
    ingredients: [
      'Entrecôte race à viande',
      'Frites maison',
      'Poivre vert',
      'Crème fraîche',
      'Romarin'
    ],
  ),

  // --- CAFÉ (COFFEE) ---
  MenuItemModel(
    id: 'cf_1',
    name: 'Espresso Barista Simple / Double',
    description:
        'Extraction pure de grains 100% Arabica d\'Éthiopie torréfiés artisanalement, aux notes chocolatées et florales surmonté d\'une crema dense.',
    price: 2.20,
    category: MenuCategory.coffee,
    imageUrl:
        'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?auto=format&fit=crop&w=800&q=80',
    rating: 4.8,
    reviewsCount: 78,
    prepTime: '3-5 min',
    calories: 5,
    ingredients: ['Arabica Éthiopie Yirgacheffe torréfaction douce'],
  ),
  MenuItemModel(
    id: 'cf_2',
    name: 'Cappuccino Velouté & Latte Art',
    description:
        'Un tiers d\'espresso corsé, un tiers de lait chaud entier et un tiers de micro-mousse onctueuse saupoudrée d\'un fin cacao bio.',
    price: 3.80,
    category: MenuCategory.coffee,
    imageUrl:
        'https://images.unsplash.com/photo-1534778101976-62847782c213?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 115,
    isPopular: true,
    prepTime: '5 min',
    calories: 120,
    ingredients: ['Espresso bio', 'Lait entier moussé', 'Poudre de cacao pur'],
  ),
  MenuItemModel(
    id: 'cf_3',
    name: 'Caramel Macchiato Glacé',
    description:
        'Lait frais glacé velouté au sirop de vanille de Madagascar, espresso intense versé en cascade et filet généreux de caramel au beurre salé.',
    price: 4.60,
    category: MenuCategory.coffee,
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 140,
    isPopular: true,
    prepTime: '5-7 min',
    calories: 240,
    ingredients: [
      'Espresso double',
      'Lait froid',
      'Glaçons',
      'Sirop vanille Bourbon',
      'Caramel beurre salé'
    ],
  ),
  MenuItemModel(
    id: 'cf_4',
    name: 'Café Turc Parfumé à la Cardamome',
    description:
        'Préparé traditionnellement dans un cezve en cuivre sur lit de sable chaud, infusé d\'une touche subtile de cardamome verte.',
    price: 2.80,
    category: MenuCategory.coffee,
    imageUrl:
        'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80',
    rating: 4.6,
    reviewsCount: 39,
    prepTime: '5-8 min',
    calories: 15,
    ingredients: ['Mouture extra fine', 'Cardamome verte', 'Sucre de canne'],
  ),

  // --- BOISSONS (DRINKS) ---
  MenuItemModel(
    id: 'dr_1',
    name: 'Mojito Passion & Menthe Fraîche',
    description:
        'Feuilles de menthe pilées au mortier, jus de citron vert pressé minute, purée de fruit de la passion exotique et eau pétillante fraîche.',
    price: 5.50,
    category: MenuCategory.drinks,
    imageUrl:
        'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 104,
    isPopular: true,
    prepTime: '5 min',
    calories: 140,
    ingredients: [
      'Menthe fraîche',
      'Citron vert',
      'Fruit de la passion',
      'Eau gazeuse',
      'Glace pilée'
    ],
  ),
  MenuItemModel(
    id: 'dr_2',
    name: 'Jus d\'Orange Pressé Minute',
    description:
        'Oranges fraîches de Valence pressées à la commande, riche en vitamines C naturelles, sans sucre ajouté ni conservateur.',
    price: 3.50,
    category: MenuCategory.drinks,
    imageUrl:
        'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=800&q=80',
    rating: 4.7,
    reviewsCount: 68,
    prepTime: '3-4 min',
    calories: 110,
    ingredients: ['100% oranges fraîches pressées'],
  ),
  MenuItemModel(
    id: 'dr_3',
    name: 'Smoothie Mangue, Ananas & Coco',
    description:
        'Mélange onctueux de mangue mûre, ananas doré, lait de coco crémeux et touche de miel sauvage pour une pause désaltérante.',
    price: 5.20,
    category: MenuCategory.drinks,
    imageUrl:
        'https://images.unsplash.com/photo-1505252585461-04db1eb84625?auto=format&fit=crop&w=800&q=80',
    rating: 4.8,
    reviewsCount: 82,
    isPopular: true,
    prepTime: '5-6 min',
    calories: 195,
    ingredients: [
      'Mangue fraîche',
      'Ananas Victoria',
      'Lait de coco bio',
      'Miel doux'
    ],
  ),
  MenuItemModel(
    id: 'dr_4',
    name: 'Thé Glacé Maison Pêche & Hibiscus',
    description:
        'Infusion lente de thé noir Ceylan et fleurs d\'hibiscus rouges, nectar de pêche de vigne et quartier de citron jaune.',
    price: 4.00,
    category: MenuCategory.drinks,
    imageUrl:
        'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?auto=format&fit=crop&w=800&q=80',
    rating: 4.6,
    reviewsCount: 45,
    prepTime: '4 min',
    calories: 90,
    ingredients: [
      'Thé noir Ceylan',
      'Fleurs d\'hibiscus',
      'Pêche de vigne',
      'Citron'
    ],
  ),

  // --- DESSERTS ---
  MenuItemModel(
    id: 'ds_1',
    name: 'Tiramisu Artisanal au Café Mascarpone',
    description:
        'Biscuits cuillères imbibés d\'espresso grand cru, crème mascarpone aérée aux œufs frais et saupoudrage généreux de chocolat noir pur.',
    price: 5.50,
    category: MenuCategory.desserts,
    imageUrl:
        'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 167,
    isPopular: true,
    isVegetarian: true,
    prepTime: '3-5 min',
    calories: 380,
    ingredients: [
      'Mascarpone italien',
      'Café espresso bio',
      'Biscuits savoiardi',
      'Cacao extra amer'
    ],
  ),
  MenuItemModel(
    id: 'ds_2',
    name: 'Fondant Cœur Coulant Chocolat Noir & Glace',
    description:
        'Gâteau au chocolat noir Valrhona 70% au cœur délicieusement coulant, servi tiède accompagné d\'une boule de glace vanille Bourbon.',
    price: 6.50,
    category: MenuCategory.desserts,
    imageUrl:
        'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=800&q=80',
    rating: 4.9,
    reviewsCount: 189,
    isPopular: true,
    isVegetarian: true,
    prepTime: '8-10 min',
    calories: 460,
    ingredients: [
      'Chocolat noir Valrhona 70%',
      'Beurre doux AOP',
      'Glace vanille de Madagascar'
    ],
  ),
  MenuItemModel(
    id: 'ds_3',
    name: 'Cheesecake Coulis de Fruits Rouges',
    description:
        'Base biscuitée croustillante au spéculoos, appareil au cream cheese onctueux et nappe veloutée de coulis de framboises fraîches.',
    price: 5.80,
    category: MenuCategory.desserts,
    imageUrl:
        'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=800&q=80',
    rating: 4.8,
    reviewsCount: 75,
    isVegetarian: true,
    prepTime: '3-5 min',
    calories: 420,
    ingredients: [
      'Cream cheese',
      'Spéculoos Lotus',
      'Coulis framboise et myrtille'
    ],
  ),
  MenuItemModel(
    id: 'ds_4',
    name: 'Crêpe Crousti-Nutella & Banane Flambée',
    description:
        'Crêpe fine bretonne dorée minute au beurre demi-sel, tartinée de pâte à tartiner chocolat noisette, rondelles de banane et éclats de noisettes.',
    price: 5.00,
    category: MenuCategory.desserts,
    imageUrl:
        'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=800&q=80',
    rating: 4.7,
    reviewsCount: 94,
    isVegetarian: true,
    prepTime: '8 min',
    calories: 440,
    ingredients: [
      'Pâte à crêpe maison',
      'Nutella',
      'Banane fraîche',
      'Noisettes torréfiées'
    ],
  ),
];
