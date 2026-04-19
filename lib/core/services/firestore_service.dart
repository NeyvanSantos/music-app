import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço de acesso ao Cloud Firestore.
///
/// Fornece uma interface centralizada para interagir com o banco de dados.
/// Todas as operações de leitura/escrita devem passar por este serviço.
class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Instância pública do Firestore para uso direto quando necessário.
  static FirebaseFirestore get instance => _db;

  // ─── Collections ─────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String playlistsCollection = 'playlists';
  static const String songsCollection = 'songs';

  /// Referência tipada para a coleção de usuários.
  static CollectionReference get users => _db.collection(usersCollection);

  /// Referência tipada para a coleção de playlists.
  static CollectionReference get playlists =>
      _db.collection(playlistsCollection);

  /// Referência tipada para a coleção de músicas.
  static CollectionReference get songs => _db.collection(songsCollection);
}
