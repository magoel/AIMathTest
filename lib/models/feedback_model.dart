import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String parentId;
  final String? profileId;
  final String message;
  final int rating; // 1-5
  final String screen; // which screen the feedback was given from
  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    required this.parentId,
    this.profileId,
    required this.message,
    required this.rating,
    required this.screen,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
    'parentId': parentId,
    'profileId': profileId,
    'message': message,
    'rating': rating,
    'screen': screen,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
