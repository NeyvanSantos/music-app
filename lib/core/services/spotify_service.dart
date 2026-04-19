import 'dart:convert';
import 'package:dio/dio.dart';

/// Serviço base de integração com a API Web do Spotify.
/// 
/// Implementa autenticação "Client Credentials" (apenas para acesso a dados públicos 
/// como busca de faixas e playlists em destaque).
class SpotifyService {
  final Dio _dio;
  
  // TODO: Crie um aplicativo no "Spotify for Developers" e cole as chaves aqui
  static const String _clientId = 'SEU_CLIENT_ID_AQUI';
  static const String _clientSecret = 'SEU_CLIENT_SECRET_AQUI';

  String? _accessToken;
  DateTime? _tokenExpiration;

  SpotifyService() : _dio = Dio(BaseOptions(baseUrl: 'https://api.spotify.com/v1/')) {
    // Interceptor para adicionar o Bearer Token em todas as requisições automaticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ignora a inserção do token caso a requisição seja para obter o próprio token
          if (!options.uri.toString().contains('accounts.spotify.com')) {
            final token = await _getValidToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Fluxo de Autenticação Client Credentials (Server-to-Server)
  /// Pega um token de acesso temporário (1 hora) gerando o base64 das credenciais
  Future<String?> _getValidToken() async {
    // 1. Otimização: Retorna o token em memória se ele ainda não estiver expirado
    if (_accessToken != null && 
        _tokenExpiration != null && 
        DateTime.now().isBefore(_tokenExpiration!)) {
      return _accessToken;
    }

    try {
      final String basicAuth = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      
      // 2. Faz a chamada passando o grant_type obrigatoriamente no URL-Encoded
      final response = await _dio.post(
        'https://accounts.spotify.com/api/token',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {'grant_type': 'client_credentials'},
      );

      _accessToken = response.data['access_token'];
      final expiresIn = response.data['expires_in'] as int;
      
      // 3. Renova com uma margem de segurança de 60 segundos antes de expirar
      _tokenExpiration = DateTime.now().add(Duration(seconds: expiresIn - 60));
      
      return _accessToken;
    } catch (e) {
      throw Exception('Erro ao autenticar com o Spotify (Client Credentials): $e');
    }
  }

  /// ─── MÉTODOS DE DADOS DA API ───────────────────────────────────────────────

  /// Buscar Músicas (Tracks)
  Future<Map<String, dynamic>> searchTracks(String query, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        'search',
        queryParameters: {
          'q': query,
          'type': 'track',
          'limit': limit,
        },
      );
      return response.data; // Retorna a estrutura bruta em JSON para manipulação futura
    } catch (e) {
      throw Exception('Erro ao buscar músicas no Spotify: $e');
    }
  }

  /// Listar Playlists (Destaques Globais / Featured)
  Future<Map<String, dynamic>> getFeaturedPlaylists({int limit = 20}) async {
    try {
      final response = await _dio.get(
        'browse/featured-playlists',
        queryParameters: {
          'limit': limit,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao pesquisar playlists em destaque: $e');
    }
  }

  /// Detalhes Específicos de uma Faixa
  Future<Map<String, dynamic>> getTrackDetails(String trackId) async {
    try {
      final response = await _dio.get('tracks/$trackId');
      return response.data;
    } catch (e) {
      throw Exception('Erro ao buscar a faixa com ID $trackId: $e');
    }
  }
}
