import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/constants.dart';

class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final void Function(String productId, PurchaseStatus status)? onPurchaseUpdate;

  SubscriptionService({this.onPurchaseUpdate});

  Future<bool> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
    return true;
  }

  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails(
      AppConstants.subscriptionProductIds,
    );
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }
    return response.productDetails;
  }

  Future<void> buySubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyPurchase(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchase.error}');
          break;
        case PurchaseStatus.pending:
          debugPrint('Purchase pending...');
          break;
        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled');
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      onPurchaseUpdate?.call(purchase.productID, purchase.status);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyPurchase');
      await callable.call({
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
        'source': 'google_play',
      });
    } catch (e) {
      debugPrint('Server verification failed: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
