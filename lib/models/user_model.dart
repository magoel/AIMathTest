import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool onboardingCompleted;
  final String? lastActiveProfileId;
  final String subscriptionPlan;
  final String subscriptionStatus;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.onboardingCompleted = false,
    this.lastActiveProfileId,
    this.subscriptionPlan = 'free',
    this.subscriptionStatus = 'none',
  });

  bool get isPremium =>
      subscriptionPlan != 'free' &&
      (subscriptionStatus == 'active' || subscriptionStatus == 'grace_period');

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      lastActiveProfileId: data['lastActiveProfileId'],
      subscriptionPlan: data['subscription']?['plan'] ?? 'free',
      subscriptionStatus: data['subscription']?['status'] ?? 'none',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    'onboardingCompleted': onboardingCompleted,
    'lastActiveProfileId': lastActiveProfileId,
    'subscription': {'plan': subscriptionPlan},
  };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    bool? onboardingCompleted,
    String? lastActiveProfileId,
    String? subscriptionPlan,
    String? subscriptionStatus,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastActiveProfileId: lastActiveProfileId ?? this.lastActiveProfileId,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }
}
