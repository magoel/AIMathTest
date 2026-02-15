import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_auth_service.dart';

final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final service = LocalAuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

final authStateProvider = StreamProvider<LocalUser?>((ref) {
  return ref.watch(localAuthServiceProvider).authStateChanges;
});
