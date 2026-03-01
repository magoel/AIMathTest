import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

@JS('Razorpay')
extension type RazorpayJS._(JSObject _) implements JSObject {
  external factory RazorpayJS(JSObject options);
  external void open();
}

class RazorpayWebService {
  final void Function(String status)? onPaymentUpdate;

  RazorpayWebService({this.onPaymentUpdate});

  Future<void> checkout({
    required String planId,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final completer = Completer<void>();

    // Create subscription server-side
    final callable = FirebaseFunctions.instance.httpsCallable('createRazorpaySubscription');
    final result = await callable.call({'planId': planId});
    final data = Map<String, dynamic>.from(result.data as Map);
    final subscriptionId = data['subscriptionId'] as String;

    final options = <String, Object?>{
      'key': AppConstants.razorpayKeyId,
      'subscription_id': subscriptionId,
      'name': AppConstants.appName,
      'description': planId == AppConstants.razorpayMonthlyPlanId
          ? 'Premium Monthly'
          : 'Premium Annual',
      'prefill': <String, Object?>{
        'name': displayName,
        'email': email,
      },
      'theme': <String, Object?>{
        'color': '#6C63FF',
      },
    }.jsify() as JSObject;

    // Set handler after jsify (function callbacks need special handling)
    options['handler'] = ((JSObject response) {
      debugPrint('Razorpay payment success');
      onPaymentUpdate?.call('success');
      if (!completer.isCompleted) completer.complete();
    }).toJS;

    final modal = <String, Object?>{}.jsify() as JSObject;
    modal['ondismiss'] = (() {
      debugPrint('Razorpay checkout dismissed');
      if (!completer.isCompleted) {
        onPaymentUpdate?.call('cancelled');
        completer.complete();
      }
    }).toJS;
    options['modal'] = modal;

    try {
      final razorpay = RazorpayJS(options);
      razorpay.open();
    } catch (e) {
      debugPrint('Razorpay checkout error: $e');
      onPaymentUpdate?.call('error');
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future;
  }
}
