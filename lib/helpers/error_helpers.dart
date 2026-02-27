import 'package:flutter/material.dart';

/// Maps raw exceptions to kid/parent-friendly error messages.
({String message, IconData icon}) friendlyError(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('network') ||
      msg.contains('clientexception') ||
      msg.contains('failed host lookup')) {
    return (
      message: 'No internet connection. Please check your WiFi and try again.',
      icon: Icons.wifi_off,
    );
  }
  if (msg.contains('resource-exhausted') || msg.contains('429')) {
    return (
      message:
          'Our math engine is busy right now. Please try again in a minute.',
      icon: Icons.hourglass_top,
    );
  }
  if (msg.contains('deadline-exceeded') || msg.contains('timeout')) {
    return (
      message:
          'This is taking too long. Please try again with fewer questions.',
      icon: Icons.timer_off,
    );
  }
  if (msg.contains('unauthenticated') || msg.contains('permission-denied')) {
    return (
      message: 'Your session has expired. Please sign out and sign back in.',
      icon: Icons.lock_outline,
    );
  }
  if (msg.contains('failed-precondition')) {
    return (
      message: 'Something went wrong on our end. Please try again shortly.',
      icon: Icons.error_outline,
    );
  }
  return (
    message: 'Something went wrong. Please try again.',
    icon: Icons.error_outline,
  );
}
