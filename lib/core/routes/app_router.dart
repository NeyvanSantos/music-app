import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/features/auth/presentation/pages/login_page.dart';
import 'package:music_app/features/home/presentation/pages/home_page.dart';
import 'package:music_app/features/search/presentation/pages/search_page.dart';
import 'package:music_app/features/library/presentation/pages/library_page.dart';
import 'package:music_app/features/library/presentation/pages/playlist_detail_page.dart';
import 'package:music_app/features/player/presentation/pages/player_page.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/models/playlist_model.dart';
import 'package:music_app/shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provedor que constrói e gerencia a instância do [GoRouter].
///
/// Ele observa [authStateChangesProvider]. Se o estado de login mudar,
/// o router fará uma reavaliação no block `redirect`.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final isGuest = ref.watch(isGuestProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) return null;

      final isAuth = authState.asData?.value != null;
      final hasAccess = isAuth || isGuest;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!hasAccess && !isLoggingIn) {
        return '/login';
      }

      if (hasAccess && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      // ─── Login (Full-Screen, sem nav bar) ──────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // ─── Shell (Tab Navigation) ────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryPage(),
            ),
          ),
        ],
      ),

      // ─── Rotas Full-Screen (fora do shell) ─────────────────
      GoRoute(
        path: '/player',
        name: 'player',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final song = state.extra as SongModel?;
          return CustomTransitionPage(
            child: PlayerPage(song: song),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),

      GoRoute(
        path: '/playlist/:id',
        name: 'playlistDetail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final playlist = state.extra as PlaylistModel?;
          if (playlist == null) {
            return const NoTransitionPage(
              child: Scaffold(
                body: Center(child: Text('Playlist não encontrada')),
              ),
            );
          }
          return CustomTransitionPage(
            child: PlaylistDetailPage(playlist: playlist),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
    ],
  );
});
