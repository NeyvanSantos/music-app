import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isIncognito;
  final bool dynamicBackground;
  final bool smartQueue;
  final bool preferVideo;
  final String updateChannel;

  SettingsState({
    this.isIncognito = false,
    this.dynamicBackground = true,
    this.smartQueue = true,
    this.preferVideo = false,
    this.updateChannel = 'stable',
  });

  bool get isPreviewChannel => updateChannel == 'preview';

  SettingsState copyWith({
    bool? isIncognito,
    bool? dynamicBackground,
    bool? smartQueue,
    bool? preferVideo,
    String? updateChannel,
  }) {
    return SettingsState(
      isIncognito: isIncognito ?? this.isIncognito,
      dynamicBackground: dynamicBackground ?? this.dynamicBackground,
      smartQueue: smartQueue ?? this.smartQueue,
      preferVideo: preferVideo ?? this.preferVideo,
      updateChannel: updateChannel ?? this.updateChannel,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyIncognito = 'settings_is_incognito';
  static const _keyDynamicBg = 'settings_dynamic_bg';
  static const _keySmartQueue = 'settings_smart_queue';
  static const _keyPreferVideo = 'settings_prefer_video';
  static const _keyUpdateChannel = 'update_channel';

  late SharedPreferences _prefs;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);

    return SettingsState(
      isIncognito: _prefs.getBool(_keyIncognito) ?? false,
      dynamicBackground: _prefs.getBool(_keyDynamicBg) ?? true,
      smartQueue: _prefs.getBool(_keySmartQueue) ?? true,
      preferVideo: _prefs.getBool(_keyPreferVideo) ?? false,
      updateChannel: _normalizeChannel(_prefs.getString(_keyUpdateChannel)),
    );
  }

  Future<void> toggleIncognito() async {
    final newValue = !state.isIncognito;
    state = state.copyWith(isIncognito: newValue);
    await _prefs.setBool(_keyIncognito, newValue);
  }

  Future<void> toggleDynamicBackground() async {
    final newValue = !state.dynamicBackground;
    state = state.copyWith(dynamicBackground: newValue);
    await _prefs.setBool(_keyDynamicBg, newValue);
  }

  Future<void> toggleSmartQueue() async {
    final newValue = !state.smartQueue;
    state = state.copyWith(smartQueue: newValue);
    await _prefs.setBool(_keySmartQueue, newValue);
  }

  Future<void> togglePreferVideo() async {
    final newValue = !state.preferVideo;
    state = state.copyWith(preferVideo: newValue);
    await _prefs.setBool(_keyPreferVideo, newValue);
  }

  Future<void> setPreviewChannel(bool enabled) async {
    final nextChannel = enabled ? 'preview' : 'stable';
    state = state.copyWith(updateChannel: nextChannel);
    await _prefs.setString(_keyUpdateChannel, nextChannel);
  }

  String _normalizeChannel(String? channel) {
    return channel == 'preview' ? 'preview' : 'stable';
  }
}
