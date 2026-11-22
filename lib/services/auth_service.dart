import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleSignInInitialization;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    final initialization = _googleSignInInitialization ??= _googleSignIn
        .initialize();
    try {
      await initialization;
    } catch (_) {
      if (identical(_googleSignInInitialization, initialization)) {
        _googleSignInInitialization = null;
      }
      rethrow;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// A null user represents the guest state; signed-in users are emitted after
/// authentication is restored or a sign-in completes.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);
