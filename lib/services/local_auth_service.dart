import 'dart:async';

/// Fake user for local demo mode.
class LocalUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  const LocalUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });
}

/// Auth service for local demo mode (no Firebase needed).
class LocalAuthService {
  LocalUser? _currentUser;
  final _controller = StreamController<LocalUser?>();

  LocalAuthService() {
    // Emit initial null state so StreamProvider resolves immediately
    _controller.add(null);
  }

  LocalUser? get currentUser => _currentUser;

  Stream<LocalUser?> get authStateChanges => _controller.stream;

  Future<LocalUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = const LocalUser(
      uid: 'demo_user_001',
      email: 'parent@demo.com',
      displayName: 'Demo Parent',
    );

    _controller.add(_currentUser);
    return _currentUser!;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
