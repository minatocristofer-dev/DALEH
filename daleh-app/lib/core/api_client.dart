import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Padrão continua sendo a API de produção (Render). Só é sobrescrita quando o
// build recebe --dart-define=API_BASE_URL=... — usado pra apontar
// temporariamente pra um backend local durante testes, sem mudar nenhum
// outro build (Android/produção continuam batendo no Render normalmente).
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://daleh-fx5c.onrender.com/v1');

enum ApiErrorKind { network, unauthorized, forbidden, notFound, conflict, badRequest, server, desconhecido }

class ApiException implements Exception {
  final String message;
  final ApiErrorKind kind;
  ApiException(this.message, {this.kind = ApiErrorKind.desconhecido});

  factory ApiException.deStatus(int status, dynamic corpoDecodificado) {
    final msg = corpoDecodificado is Map ? corpoDecodificado['message'] : null;
    final mensagem = msg is List
        ? msg.join(', ')
        : (msg?.toString() ?? _mensagemPadraoPara(status));

    ApiErrorKind kind;
    switch (status) {
      case 401:
        kind = ApiErrorKind.unauthorized;
        break;
      case 403:
        kind = ApiErrorKind.forbidden;
        break;
      case 404:
        kind = ApiErrorKind.notFound;
        break;
      case 409:
        kind = ApiErrorKind.conflict;
        break;
      case 400:
        kind = ApiErrorKind.badRequest;
        break;
      default:
        kind = status >= 500 ? ApiErrorKind.server : ApiErrorKind.desconhecido;
    }
    return ApiException(mensagem, kind: kind);
  }

  static String _mensagemPadraoPara(int status) {
    if (status >= 500) return 'O servidor do DALEH teve um problema. Tenta de novo em instantes.';
    return 'Algo deu errado. Tenta de novo.';
  }

  @override
  String toString() => message;
}

class ApiClient {
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? corpo,
    String? token,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response resp;
    try {
      switch (method) {
        case 'GET':
          resp = await http.get(uri, headers: headers);
          break;
        case 'POST':
          resp = await http.post(uri, headers: headers, body: jsonEncode(corpo ?? {}));
          break;
        case 'PATCH':
          resp = await http.patch(uri, headers: headers, body: jsonEncode(corpo ?? {}));
          break;
        case 'DELETE':
          resp = await http.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Método HTTP não suportado: $method');
      }
    } on SocketException {
      throw ApiException('Sem conexão com a internet. Verifica sua rede e tenta de novo.', kind: ApiErrorKind.network);
    } on http.ClientException {
      throw ApiException('Não foi possível falar com o servidor do DALEH.', kind: ApiErrorKind.network);
    }

    final corpoResp = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException.deStatus(resp.statusCode, corpoResp);
    }
    return corpoResp;
  }

  Future<Map<String, dynamic>> _post(String caminho, Map<String, dynamic> corpo) async {
    final dados = await _request('POST', caminho, corpo: corpo);
    return (dados as Map<String, dynamic>?) ?? {};
  }

  Future<String> registrar(Map<String, dynamic> dto) async {
    final resp = await _post('/auth/register', dto);
    return resp['accessToken'] as String;
  }

  Future<String> login(String email, String senha) async {
    final resp = await _post('/auth/login', {'email': email, 'password': senha});
    return resp['accessToken'] as String;
  }

  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) async {
    final resp = await _post('/auth/social', {
      'accessToken': accessTokenSupabase,
      'consentimentoDadosSensiveis': consentimento,
    });
    return resp['accessToken'] as String;
  }

  // --- Chamadas autenticadas genéricas, usadas pelos repositórios de cada feature ---

  Future<List<dynamic>> getLista(String path, {required String token}) async {
    final dados = await _request('GET', path, token: token);
    return (dados as List?) ?? [];
  }

  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async {
    final dados = await _request('GET', path, token: token);
    return (dados as Map<String, dynamic>?) ?? {};
  }

  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) {
    return _request('POST', path, token: token, corpo: corpo);
  }

  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    final dados = await _request('PATCH', path, token: token, corpo: corpo);
    return (dados as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    final dados = await _request('DELETE', path, token: token);
    return (dados as Map<String, dynamic>?) ?? {};
  }

  // Upload multipart — usado por `POST /users/me/avatar` (foto de perfil) e
  // `POST /teams/:id/crest` (escudo do time).
  Future<Map<String, dynamic>> enviarArquivo(
    String path, {
    required String token,
    required List<int> bytes,
    required String nomeArquivo,
    required String contentType,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      // Sem `contentType`, o pacote `http` manda "application/octet-stream"
      // por padrão — o backend recusa isso (só aceita image/png e
      // image/jpeg).
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: nomeArquivo,
        contentType: MediaType.parse(contentType),
      ));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } on SocketException {
      throw ApiException('Sem conexão com a internet. Verifica sua rede e tenta de novo.', kind: ApiErrorKind.network);
    } on http.ClientException {
      throw ApiException('Não foi possível falar com o servidor do DALEH.', kind: ApiErrorKind.network);
    }

    final resp = await http.Response.fromStream(streamed);
    final corpoResp = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException.deStatus(resp.statusCode, corpoResp);
    }
    return (corpoResp as Map<String, dynamic>?) ?? {};
  }
}
