import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService extends ChangeNotifier {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;

  ReviewService._internal() {
    _initReviews();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewsSub;

  List<ReviewModel> _reviews = [];

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);
  int get totalCount => _reviews.length;

  void _initReviews() {
    _reviewsSub = _db
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _reviews = snapshot.docs.map((doc) {
          return ReviewModel.fromJson({...doc.data(), 'id': doc.id});
        }).toList();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('⚠️ [ReviewService] Firestore listen error: $e');
      },
    );
  }

  /// Check if a specific order has already been reviewed
  bool isOrderReviewed(String? orderId) {
    if (orderId == null || orderId.isEmpty) return false;
    return _reviews.any((r) => r.orderId == orderId);
  }

  /// Get the existing review for an order if present
  ReviewModel? getReviewForOrder(String? orderId) {
    if (orderId == null || orderId.isEmpty) return null;
    return _reviews.where((r) => r.orderId == orderId).firstOrNull;
  }

  /// Average overall rating (0.0 if no reviews)
  double get averageOverall {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<double>(0.0, (acc, r) => acc + r.overallRating);
    return double.parse((sum / _reviews.length).toStringAsFixed(1));
  }

  /// Average food rating
  double get averageFood {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.foodRating);
    return double.parse((sum / _reviews.length).toStringAsFixed(1));
  }

  /// Average service rating
  double get averageService {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.serviceRating);
    return double.parse((sum / _reviews.length).toStringAsFixed(1));
  }

  /// Average speed rating
  double get averageSpeed {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.speedRating);
    return double.parse((sum / _reviews.length).toStringAsFixed(1));
  }

  /// Average ambiance rating
  double get averageAmbiance {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.ambianceRating);
    return double.parse((sum / _reviews.length).toStringAsFixed(1));
  }

  /// Average value rating
  double get averageValue {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.valueRating);
    return double.parse((sum / _reviews.length).toStringAsFixed(1));
  }

  /// Percentage of clients who would recommend the restaurant (0 - 100)
  int get recommendationRatePercentage {
    if (_reviews.isEmpty) return 100;
    final positive = _reviews.where((r) => r.wouldRecommend).length;
    return ((positive / _reviews.length) * 100).round();
  }

  /// Distribution of overall star ratings: counts for 5, 4, 3, 2, 1
  Map<int, int> get starDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final rounded = r.overallRating.round().clamp(1, 5);
      dist[rounded] = (dist[rounded] ?? 0) + 1;
    }
    return dist;
  }

  /// Submit a new review to Firestore (Create of CRUD)
  Future<void> submitReview(ReviewModel review) async {
    try {
      if (review.id.isNotEmpty) {
        await updateReview(review);
        return;
      }
      final docRef = _db.collection('reviews').doc();
      final data = review.toJson();
      data['id'] = docRef.id;
      await docRef.set(data);
    } catch (e) {
      debugPrint('⚠️ [ReviewService] Error saving review: $e');
      rethrow;
    }
  }

  /// Update an existing review in Firestore (Update of CRUD)
  Future<void> updateReview(ReviewModel review) async {
    try {
      if (review.id.isEmpty) {
        throw Exception('Review ID is required to update');
      }
      final data = review.toJson();
      await _db.collection('reviews').doc(review.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ [ReviewService] Error updating review: $e');
      rethrow;
    }
  }

  /// Delete a review (Delete of CRUD)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _db.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      debugPrint('⚠️ [ReviewService] Error deleting review: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    super.dispose();
  }
}
