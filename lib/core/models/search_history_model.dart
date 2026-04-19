import 'dart:convert';

class SearchHistoryEntry {
  final String query;
  final String type; // 'Música', 'Artista', 'Playlist', 'Busca'
  final DateTime timestamp;

  SearchHistoryEntry({
    required this.query,
    this.type = 'Busca',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      query: map['query'] ?? '',
      type: map['type'] ?? 'Busca',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory SearchHistoryEntry.fromJson(String source) =>
      SearchHistoryEntry.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistoryEntry && other.query == query;
  }

  @override
  int get hashCode => query.hashCode;
}
