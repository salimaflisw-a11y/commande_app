import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final DateTime createdAt;
  final String? clientId;
  final String clientName;
  final String? clientPhone;
  final String? orderId;
  final String? orderNumber;
  final String? orderType;
  final String? tableNumber;

  // Aspect ratings (1 to 5)
  final int foodRating;
  final List<String> foodTags;

  final int serviceRating;
  final List<String> serviceTags;

  final int speedRating;
  final List<String> speedTags;

  final int ambianceRating;
  final List<String> ambianceTags;

  final int valueRating;
  final List<String> valueTags;

  // Global assessment
  final double overallRating;
  final bool wouldRecommend;
  final String additionalNote;

  const ReviewModel({
    required this.id,
    required this.createdAt,
    this.clientId,
    required this.clientName,
    this.clientPhone,
    this.orderId,
    this.orderNumber,
    this.orderType,
    this.tableNumber,
    required this.foodRating,
    this.foodTags = const [],
    required this.serviceRating,
    this.serviceTags = const [],
    required this.speedRating,
    this.speedTags = const [],
    required this.ambianceRating,
    this.ambianceTags = const [],
    required this.valueRating,
    this.valueTags = const [],
    required this.overallRating,
    this.wouldRecommend = true,
    this.additionalNote = '',
  });

  /// Factory helper that calculates the overall rating from individual aspects
  factory ReviewModel.create({
    String id = '',
    DateTime? createdAt,
    String? clientId,
    required String clientName,
    String? clientPhone,
    String? orderId,
    String? orderNumber,
    String? orderType,
    String? tableNumber,
    required int foodRating,
    List<String> foodTags = const [],
    required int serviceRating,
    List<String> serviceTags = const [],
    required int speedRating,
    List<String> speedTags = const [],
    required int ambianceRating,
    List<String> ambianceTags = const [],
    required int valueRating,
    List<String> valueTags = const [],
    bool wouldRecommend = true,
    String additionalNote = '',
  }) {
    final computedOverall = (foodRating + serviceRating + speedRating + ambianceRating + valueRating) / 5.0;
    return ReviewModel(
      id: id,
      createdAt: createdAt ?? DateTime.now(),
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      orderId: orderId,
      orderNumber: orderNumber,
      orderType: orderType,
      tableNumber: tableNumber,
      foodRating: foodRating,
      foodTags: foodTags,
      serviceRating: serviceRating,
      serviceTags: serviceTags,
      speedRating: speedRating,
      speedTags: speedTags,
      ambianceRating: ambianceRating,
      ambianceTags: ambianceTags,
      valueRating: valueRating,
      valueTags: valueTags,
      overallRating: double.parse(computedOverall.toStringAsFixed(1)),
      wouldRecommend: wouldRecommend,
      additionalNote: additionalNote,
    );
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        parsedDate = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        parsedDate = DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
      }
    }

    final food = (json['foodRating'] as num?)?.toInt() ?? 5;
    final service = (json['serviceRating'] as num?)?.toInt() ?? 5;
    final speed = (json['speedRating'] as num?)?.toInt() ?? 5;
    final ambiance = (json['ambianceRating'] as num?)?.toInt() ?? 5;
    final value = (json['valueRating'] as num?)?.toInt() ?? 5;

    final overall = (json['overallRating'] as num?)?.toDouble() ??
        ((food + service + speed + ambiance + value) / 5.0);

    return ReviewModel(
      id: json['id'] as String? ?? '',
      createdAt: parsedDate,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String? ?? 'Client',
      clientPhone: json['clientPhone'] as String?,
      orderId: json['orderId'] as String?,
      orderNumber: json['orderNumber'] as String?,
      orderType: json['orderType'] as String?,
      tableNumber: json['tableNumber'] as String?,
      foodRating: food,
      foodTags: (json['foodTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      serviceRating: service,
      serviceTags: (json['serviceTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      speedRating: speed,
      speedTags: (json['speedTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      ambianceRating: ambiance,
      ambianceTags: (json['ambianceTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      valueRating: value,
      valueTags: (json['valueTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      overallRating: overall,
      wouldRecommend: json['wouldRecommend'] as bool? ?? true,
      additionalNote: json['additionalNote'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': Timestamp.fromDate(createdAt),
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'orderType': orderType,
      'tableNumber': tableNumber,
      'foodRating': foodRating,
      'foodTags': foodTags,
      'serviceRating': serviceRating,
      'serviceTags': serviceTags,
      'speedRating': speedRating,
      'speedTags': speedTags,
      'ambianceRating': ambianceRating,
      'ambianceTags': ambianceTags,
      'valueRating': valueRating,
      'valueTags': valueTags,
      'overallRating': overallRating,
      'wouldRecommend': wouldRecommend,
      'additionalNote': additionalNote,
    };
  }
}
