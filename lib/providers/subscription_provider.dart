import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import '../services/subscription_service.dart';
import 'user_provider.dart';

/// The subscription service singleton.
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService(
    onPurchaseUpdate: (productId, status) {
      // Refresh user data from Firestore after purchase status changes
      ref.invalidate(userProvider);
    },
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Whether billing is available on this platform.
final billingAvailableProvider = FutureProvider<bool>((ref) async {
  if (!AppConfig.useFirebase) return false;
  if (kIsWeb) return false;
  if (!Platform.isAndroid) return false;

  final service = ref.read(subscriptionServiceProvider);
  return await service.initialize();
});

/// Available products from Google Play.
final subscriptionProductsProvider =
    FutureProvider<List<ProductDetails>>((ref) async {
  final available = await ref.watch(billingAvailableProvider.future);
  if (!available) return [];
  final service = ref.read(subscriptionServiceProvider);
  return await service.getProducts();
});

/// Convenience: is current user premium?
final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider).valueOrNull;
  return user?.isPremium ?? false;
});
