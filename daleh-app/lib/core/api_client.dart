import 'dart:convert';
import 'package:http/http.dart' as http;

const apiBaseUrl = 'https://daleh-fx5c.onrender.com/v1';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  Future<Map<String, dynamic>> _post(String caminho, Map<String, dynamic> corpo) async {
    final resp = await http.post(
      Uri.parse('$apiBaseUrl$caminho'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(corpo),
    );

    final dados = resp.body.isNotEmpty ? jsonDecode(resp.body) as Map<String, dynamic> : <String, dynamic>{};

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = dados['message'];
      final mensagem = msg is List ? msg.join(', ') : (msg?.toString() ?? 'Algo deu errado. Tenta de novo.');
      throw ApiException(mensagem);
    }
    return dados;
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
}
