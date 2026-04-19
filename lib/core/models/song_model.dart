enum SongSource { local, youtube }

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final String? audioUrl;
  final String? youtubeId;
  final SongSource source;
  final DateTime? createdAt;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    this.audioUrl,
    this.youtubeId,
    this.source = SongSource.local,
    this.createdAt,
  });

  factory SongModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SongModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      audioUrl: map['audioUrl'],
      youtubeId: map['youtubeId'],
      source: SongSource.values.byName(map['source'] ?? 'local'),
      createdAt:
          map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
      'youtubeId': youtubeId,
      'source': source.name,
      'createdAt': createdAt?.toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory SongModel.fromYouTube(dynamic video) {
    return SongModel(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      thumbnailUrl: video.thumbnails.highResUrl,
      youtubeId: video.id.value,
      source: SongSource.youtube,
      createdAt: DateTime.now().toUtc(),
    );
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? audioUrl,
    String? youtubeId,
    SongSource? source,
    DateTime? createdAt,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      youtubeId: youtubeId ?? this.youtubeId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get effectiveThumbnailUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    if (source == SongSource.youtube) {
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return '';
  }
}
