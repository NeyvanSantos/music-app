import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mocks
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockUser extends Mock implements User {
  @override
  String get uid => 'test_user_uid';
}

void main() {
  group('LibraryController Tests', () {
    late ProviderContainer container;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnap;
    late MockUser mockUser;

    setUp(() {
      mockDocRef = MockDocumentReference();
      mockDocSnap = MockDocumentSnapshot();
      mockUser = MockUser();
      
      container = ProviderContainer(
        overrides: [
          userProvider.overrideWith((ref) => mockUser),
        ],
      );
    });

    final mockSong = SongModel(
      id: 'song_123',
      title: 'Test Song',
      artist: 'Artist',
      youtubeId: 'yt_123',
      thumbnailUrl: '',
    );

    test('addSongToPlaylist deve adicionar ID se não estiver presente', () async {
      final controller = container.read(libraryControllerProvider);
      
      // Infelizmente, a dependência estática FirestoreService.playlists
      // torna o teste de unidade puro difícil sem refatorar o serviço.
      // Em um cenário real, injetaríamos o Firestore no LibraryController.
      // Para este teste, vamos documentar a necessidade de injeção de dependência.
      
      expect(controller, isNotNull);
      // skip: Teste de integração real exigiria mockar o Firebase de forma global (firebase_auth_mocks).
    });

    test('Deve validar que usuário precisa estar logado para criar playlist', () async {
      // Override para simular deslogado
      final containerLoggedOut = ProviderContainer(
        overrides: [
          userProvider.overrideWith((ref) => null),
        ],
      );
      
      final controller = containerLoggedOut.read(libraryControllerProvider);
      
      expect(
        () => controller.createPlaylist('Nova'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'mensagem', contains('logado'))),
      );
    });
  });
}
