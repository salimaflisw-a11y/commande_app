class CategoryModel {
  final String id;
  final String label;
  final String emoji;
  final String subtitle;
  final String bannerImageUrl;

  const CategoryModel({
    required this.id,
    required this.label,
    required this.emoji,
    this.subtitle = '',
    this.bannerImageUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'emoji': emoji,
      'subtitle': subtitle,
      'bannerImageUrl': bannerImageUrl,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🍽️',
      subtitle: json['subtitle']?.toString() ?? '',
      bannerImageUrl: json['bannerImageUrl']?.toString() ?? '',
    );
  }

  CategoryModel copyWith({
    String? id,
    String? label,
    String? emoji,
    String? subtitle,
    String? bannerImageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      subtitle: subtitle ?? this.subtitle,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
    );
  }
}
