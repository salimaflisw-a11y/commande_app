class SupplementModel {
  final String id;
  final String name;
  final String category;
  final String icon;
  final double price;
  final bool isAvailable;

  const SupplementModel({
    required this.id,
    required this.name,
    required this.category,
    this.icon = '➕',
    required this.price,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
      'price': price,
      'isAvailable': isAvailable,
    };
  }

  factory SupplementModel.fromJson(Map<String, dynamic> json) {
    return SupplementModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString().trim() ?? '',
      icon: (json['icon']?.toString().trim().isNotEmpty ?? false)
          ? json['icon'].toString().trim()
          : '➕',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  SupplementModel copyWith({
    String? id,
    String? name,
    String? category,
    String? icon,
    double? price,
    bool? isAvailable,
  }) {
    return SupplementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
