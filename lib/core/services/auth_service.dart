import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/core/services/firestore_service.dart';

/// Exceção personalizada de Autenticação.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Serviço de autenticação Firebase.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Instância do GoogleSignIn (v7.x+)
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  /// Retorna se a plataforma atual suporta nativamente o plugin oficial.
  static bool get _supportsGoogleSignIn {
    if (kIsWeb) return true;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) return true;
    return false;
  }

  /// Inicializa serviços estáticos.
  static Future<void> initializeStaticServices() async {
    try {
      if (_supportsGoogleSignIn) {
        await _googleSignIn.initialize(
          serverClientId: '457284911122-9a09ct7egt23i12c4vuup2sf01d72oj0.apps.googleusercontent.com',
        );
      }
    } catch (e) {
      // Ignora de forma silenciosa para não quebrar no desktop
    }
  }

  /// Autentica o usuário utilizando Google Sign-In (v7.x+).
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_supportsGoogleSignIn) {
        throw AuthException('Google Sign-In ainda não é suportado no Windows.');
      }

      // 1. Autenticação básica
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      // 2. Obtenção do idToken
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Obtenção do accessToken (requer autorização explícita na v7+)
      const List<String> scopes = ['email', 'profile', 'openid'];
      final GoogleSignInClientAuthorization authorization = 
          await googleUser.authorizationClient.authorizeScopes(scopes);

      // 4. Criação da credencial Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in no Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 6. Sincronização Firestore
      if (userCredential.user != null) {
        await _syncUserDataToFirestore(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Erro no Firebase Auth.');
    } catch (e) {
      throw AuthException('Erro no Google Sign-In: $e');
    }
  }


  static Future<void> _syncUserDataToFirestore(User user) async {
    final userDoc = FirestoreService.users.doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'lastLogin': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      await userDoc.update({
        'lastLogin': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Erro ao deslogar: $e');
    }
  }
}
