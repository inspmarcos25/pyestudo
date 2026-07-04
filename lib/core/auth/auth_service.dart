import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Login com Google ou e-mail/senha via Firebase Auth.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-canceled',
        message: 'login cancelado',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}

/// Traduz códigos de erro do Firebase Auth para mensagens em PT-BR.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'e-mail inválido';
    case 'user-disabled':
      return 'esta conta foi desativada';
    case 'user-not-found':
      return 'nenhuma conta encontrada com esse e-mail';
    case 'wrong-password':
    case 'invalid-credential':
      return 'senha incorreta';
    case 'email-already-in-use':
      return 'já existe uma conta com esse e-mail';
    case 'weak-password':
      return 'a senha precisa ter pelo menos 6 caracteres';
    case 'sign-in-canceled':
      return 'login cancelado';
    case 'unauthorized-domain':
      return 'este domínio não está autorizado para login com Google';
    default:
      return 'não foi possível entrar: ${e.message ?? e.code}';
  }
}
