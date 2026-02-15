import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/local_auth_service.dart';

// Local auth service
final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final service = LocalAuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Firebase auth service
final firebaseAuthServiceProvider = Provider<AuthService>((ref) => AuthService());

// Unified auth state — returns LocalUser? in both modes
final authStateProvider = StreamProvider<LocalUser?>((ref) {
  if (AppConfig.useFirebase) {
    return ref.watch(firebaseAuthServiceProvider).authStateChanges.map(
      (fb.User? user) => user == null
          ? null
          : LocalUser(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              photoURL: user.photoURL,
            ),
    );
  }
  return ref.watch(localAuthServiceProvider).authStateChanges;
});
