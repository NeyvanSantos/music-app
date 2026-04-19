class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final int? color; // Color in int, like 0xFF3A2060
  final String? coverUrl;
  final String userId;
  final DateTime? createdAt;
  final List<String> songIds;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.coverUrl,
    required this.userId,
    this.createdAt,
    this.songIds = const [],
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return PlaylistModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      color:
          map['color'] != null ? int.tryParse(map['color'].toString()) : null,
      coverUrl: map['coverUrl'],
      userId: map['userId'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'coverUrl': coverUrl,
      'userId': userId,
      'songIds': songIds,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Criar uma nova playlist com um song adicionado
  PlaylistModel addSong(String songId) {
    if (songIds.contains(songId)) {
      return this;
    }
    return PlaylistModel(
      id: id,
      name: name,
      description: description,
      color: color,
      coverUrl: coverUrl,
      userId: userId,
      createdAt: createdAt,
      songIds: [...songIds, songId],
    );
  }

  // Remover uma música da playlist
  PlaylistModel removeSong(String songId) {
    return PlaylistModel(
      id: id,
      name: name,
      description: description,
      color: color,
      coverUrl: coverUrl,
      userId: userId,
      createdAt: createdAt,
      songIds: songIds.where((id) => id != songId).toList(),
    );
  }
}
