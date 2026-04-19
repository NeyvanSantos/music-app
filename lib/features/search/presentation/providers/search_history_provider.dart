import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/core/models/search_history_model.dart';
import 'package:music_app/features/settings/presentation/providers/settings_provider.dart';

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(() {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends Notifier<List<SearchHistoryEntry>> {
  static const _key = 'search_history';
  late SharedPreferences _prefs;

  @override
  List<SearchHistoryEntry> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    
    final jsonList = _prefs.getStringList(_key);
    if (jsonList != null) {
      return jsonList
          .map((item) => SearchHistoryEntry.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<void> addEntry(String query, {String type = 'Busca'}) async {
    // Verifica Modo Incógnito
    final isIncognito = ref.read(settingsProvider).isIncognito;
    if (isIncognito) return;

    // Remove se já existir para mover ao topo
    final newState = List<SearchHistoryEntry>.from(state)
      ..removeWhere((e) => e.query.toLowerCase() == query.toLowerCase());

    // Adiciona ao início
    newState.insert(
      0,
      SearchHistoryEntry(
        query: query,
        type: type,
        timestamp: DateTime.now(),
      ),
    );

    // Limita a 10 itens
    if (newState.length > 10) {
      newState.removeLast();
    }

    state = newState;
    await _save();
  }

  Future<void> removeEntry(String query) async {
    state = state.where((e) => e.query != query).toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    await _save();
  }

  Future<void> _save() async {
    final jsonList = state.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_key, jsonList);
  }
}
