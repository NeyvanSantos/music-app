import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';

class SleepTimerState {
  final int? remainingMinutes;
  final bool isActive;

  SleepTimerState({this.remainingMinutes, this.isActive = false});

  SleepTimerState copyWith({int? remainingMinutes, bool? isActive}) {
    return SleepTimerState(
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      isActive: isActive ?? this.isActive,
    );
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, SleepTimerState>(() {
  return SleepTimerNotifier();
});

class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return SleepTimerState();
  }

  void setTimer(int minutes) {
    _timer?.cancel();
    state = SleepTimerState(remainingMinutes: minutes, isActive: true);

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final current = state.remainingMinutes ?? 0;
      if (current <= 1) {
        _stopMusic();
      } else {
        state = state.copyWith(remainingMinutes: current - 1);
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    state = SleepTimerState();
  }

  void _stopMusic() {
    _timer?.cancel();
    state = SleepTimerState();
    
    // Pausa a música através do playerProvider
    ref.read(playerProvider.notifier).pause();
  }
}
