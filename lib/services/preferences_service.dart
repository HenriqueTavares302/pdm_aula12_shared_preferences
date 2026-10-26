import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyNomeUsuario = 'key_nome_usuario';
  static const String _keyModoEscuro = 'key_modo_escuro';
  static const String _keyUltimoAcesso = 'key_ultimo_acesso';
  static const String _keyHistorico = 'key_historico';

  static const int _limiteHistorico = 10;

  Future<void> salvarNomeUsuario(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNomeUsuario, nome);
  }

  Future<String> obterNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNomeUsuario) ?? 'Usuário Convidado';
  }

  Future<void> salvarModoEscuro(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyModoEscuro, valor);
  }

  Future<bool> obterModoEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyModoEscuro) ?? false;
  }

  Future<void> registrarAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimoAcesso, DateTime.now().toString());
  }

  Future<String?> obterUltimoAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUltimoAcesso);
  }

  Future<List<Map<String, dynamic>>> obterHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_keyHistorico);

    if (bruto == null || bruto.isEmpty) return [];

    try {
      final List<dynamic> lista = jsonDecode(bruto);
      return lista.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> adicionarAoHistorico(String nome, bool modoEscuro) async {
    final prefs = await SharedPreferences.getInstance();
    final historico = await obterHistorico();

    historico.insert(0, {
      'nome': nome,
      'modoEscuro': modoEscuro,
      'data': DateTime.now().toString(),
    });

    final limitado = historico.take(_limiteHistorico).toList();
    await prefs.setString(_keyHistorico, jsonEncode(limitado));
  }

  Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}