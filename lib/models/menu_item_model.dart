class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  /// Label of the Firestore category this item belongs to
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final bool isPopular;
  final bool isVegetarian;
  final String prepTime;
  final int calories;
  final List<String> ingredients;

  String get categoryLabel => category.trim();

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
    String? category,
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
      'category': category,
      'customCategory': category,
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: (json['customCategory']?.toString().trim().isNotEmpty ?? false)
          ? json['customCategory'].toString().trim()
          : json['category']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      isPopular: json['isPopular'] as bool? ?? false,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      prepTime: json['prepTime']?.toString() ?? '15 min',
      calories: (json['calories'] as num?)?.toInt() ?? 400,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
