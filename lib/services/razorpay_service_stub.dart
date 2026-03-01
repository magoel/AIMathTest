import 'dart:async';

class RazorpayWebService {
  final void Function(String status)? onPaymentUpdate;
  RazorpayWebService({this.onPaymentUpdate});

  Future<void> checkout({
    required String planId,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    throw UnsupportedError('Razorpay is only available on web');
  }
}
