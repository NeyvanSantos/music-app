import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/app.dart';
import 'package:music_app/core/services/firebase_service.dart';
import 'package:music_app/core/services/auth_service.dart';
import 'package:music_app/core/services/audio_handler.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';
import 'package:music_app/core/services/local_storage_service.dart';
import 'package:music_app/core/services/version_guard_service.dart';
import 'package:music_app/core/services/supabase_service.dart';

/// Handler global de áudio
MusicHandler? audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializa SharedPreferences antes de tudo
  final sharedPrefs = await SharedPreferences.getInstance();

  // Força estilo da barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const AppBootstrapper(),
    ),
  );
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // 0. Version Guard (Deep Clean se necessário)
      // Fazemos isso antes do Firebase para garantir que o cache seja limpo.
      try {
        await VersionGuardService.performDeepCleanIfNeeded();
      } catch (e) {
        debugPrint('⚠️ VersionGuard failed: $e');
      }

      // 1. Firebase, Supabase & Local Storage
      try {
        await SupabaseService.initialize();
        await FirebaseService.initialize();
        await LocalStorageService.init();
      } catch (e) {
        debugPrint('⚠️ Core services init failed: $e');
      }

      // AudioHandler
      try {
        audioHandler = await AudioService.init(
          builder: () => MusicHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.neyva.somax.audio',
            androidNotificationChannelName: 'Somax',
            androidNotificationOngoing: false, // Permite remover a notificação se pausado
            androidStopForegroundOnPause: true, // Para o serviço se pausar (ajuda na remoção)
            androidNotificationIcon: 'mipmap/launcher_icon',
            androidShowNotificationBadge: true,
          ),
        );
      } catch (e) {
        debugPrint('⚠️ AudioService init failed: $e');
      }

      // Auth
      try {
        await AuthService.initializeStaticServices();
      } catch (e) {
        debugPrint('⚠️ AuthService init failed: $e');
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('CRITICAL INIT ERROR: $e');
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0A0A0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 24),
                Text(
                  'Iniciando Música...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MusicApp();
  }
}
