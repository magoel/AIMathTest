import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/constants.dart';
import '../providers/subscription_provider.dart';

class UpgradeDialog extends ConsumerStatefulWidget {
  const UpgradeDialog({super.key});

  @override
  ConsumerState<UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends ConsumerState<UpgradeDialog> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(subscriptionProductsProvider);

    return AlertDialog(
      title: const Text('Upgrade to Premium'),
      content: SizedBox(
        width: 340,
        child: productsAsync.when(
          data: (products) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unlock unlimited tests for your kids!'),
              const SizedBox(height: 16),
              _featureRow(Icons.all_inclusive, 'Unlimited daily tests'),
              _featureRow(Icons.family_restroom, 'All profiles included'),
              const SizedBox(height: 16),
              if (products.isEmpty)
                const Text(
                  'No subscription plans available right now. Please try again later.',
                  style: TextStyle(color: Colors.grey),
                ),
              ...products.map((product) => _productCard(product)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _purchasing ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load plans: $e'),
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Subscribe'),
        ),
      ),
    );
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
