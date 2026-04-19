import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/config/preview_access_config.dart';
import 'package:music_app/core/services/auth_service.dart';

/// Provedor que rastreia os estados completos do Auth (Logged in, Logged out, Mudanças)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// Provedor que retorna diretamente o Usuário atual, se existir.
final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.asData?.value;
});

final previewAccessProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestProvider);
  final user = ref.watch(userProvider);

  if (isGuest || user == null) {
    return false;
  }

  final email = user.email?.trim().toLowerCase();
  if (email == null || email.isEmpty) {
    return false;
  }

  return allowedPreviewEmails.contains(email);
});

/// Provedor que rastreia se o usuário está no modo convidado local (sem conta).
/// Provedor que rastreia se o usuário está no modo convidado local (sem conta).
final isGuestProvider =
    NotifierProvider<GuestNotifier, bool>(GuestNotifier.new);

class GuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setGuest(bool value) {
    state = value;
  }
}

/// Provedor de lógica para ações na interface (Login/Logout).
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Realiza a chamada do Sign In pelo Google.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await AuthService.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Ativa o modo convidado local, permitindo acesso ao app sem conta Firebase.
  void enterAsGuest() {
    ref.read(isGuestProvider.notifier).setGuest(true);
  }

  /// Realiza a desconexão do usuário atual.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await AuthService.signOut();
      ref.read(isGuestProvider.notifier).setGuest(false);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
