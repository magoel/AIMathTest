import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import '../services/razorpay_service.dart';

class UpgradeDialog extends ConsumerStatefulWidget {
  const UpgradeDialog({super.key});

  @override
  ConsumerState<UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends ConsumerState<UpgradeDialog> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upgrade to Premium'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unlock unlimited tests for your kids!'),
            const SizedBox(height: 16),
            _featureRow(Icons.all_inclusive, 'Unlimited daily tests'),
            _featureRow(Icons.family_restroom, 'All profiles included'),
            const SizedBox(height: 16),
            if (kIsWeb) ..._buildWebPlans() else ..._buildAndroidPlans(),
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _purchasing ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not Now'),
        ),
      ],
    );
  }

  List<Widget> _buildWebPlans() {
    return [
      _planCard(
        title: 'Monthly',
        price: '\u20B950/month',
        onTap: () => _purchaseWeb(AppConstants.razorpayMonthlyPlanId),
      ),
      _planCard(
        title: 'Annual',
        price: '\u20B9500/year (save 17%)',
        onTap: () => _purchaseWeb(AppConstants.razorpayAnnualPlanId),
      ),
    ];
  }

  List<Widget> _buildAndroidPlans() {
    final productsAsync = ref.watch(subscriptionProductsProvider);
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return [
            const Text(
              'No subscription plans available right now. Please try again later.',
              style: TextStyle(color: Colors.grey),
            ),
          ];
        }
        return products.map((p) => _productCard(p)).toList();
      },
      loading: () => [
        const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [Text('Could not load plans: $e')],
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: ElevatedButton(
          onPressed: _purchasing ? null : onTap,
          child: _purchasing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe'),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _productCard(ProductDetails product) {
    final isAnnual = product.id == AppConstants.annualProductId;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(isAnnual ? 'Annual' : 'Monthly'),
        subtitle: Text(product.price),
        trailing: ElevatedButton(
          onPressed: _purchasing ? null : () => _purchase(product),
          child: _purchasing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe'),
        ),
      ),
    );
  }

  Future<void> _purchaseWeb(String planId) async {
    setState(() => _purchasing = true);
    try {
      final authUser = ref.read(authStateProvider).valueOrNull;
      if (authUser == null) throw Exception('Not signed in');

      final user = ref.read(userProvider).valueOrNull;
      final service = RazorpayWebService(
        onPaymentUpdate: (status) {
          if (status == 'success') {
            ref.invalidate(userProvider);
          }
        },
      );

      await service.checkout(
        planId: planId,
        userId: authUser.uid,
        email: authUser.email,
        displayName: user?.displayName ?? 'Parent',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _purchase(ProductDetails product) async {
    setState(() => _purchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.buySubscription(product);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}
