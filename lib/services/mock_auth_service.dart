import 'dart:async';

import 'auth_service.dart';

/// In-memory Mock implementation of [AuthService] for testing and offline demo.
class MockAuthService implements AuthService {
  MockAuthService({
    String? initialUserId = 'test_p02_duc',
    String? initialEmail = 'ducnmse180000@fpt.edu.vn',
  })  : _currentUserId = initialUserId,
        _currentUserEmail = initialEmail {
    _controller = StreamController<bool>.broadcast(
      onListen: () => _controller.add(_currentUserId != null),
    );
  }

  String? _currentUserId;
  String? _currentUserEmail;
  late final StreamController<bool> _controller;

  @override
  String? get currentUserId => _currentUserId;

  @override
  String? get currentUserEmail => _currentUserEmail;

  @override
  Stream<bool> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithGoogle() async {
    _currentUserId = 'test_p02_duc';
    _currentUserEmail = 'ducnmse180000@fpt.edu.vn';
    _controller.add(true);
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _currentUserEmail = null;
    _controller.add(false);
  }

  void dispose() {
    _controller.close();
  }
}
