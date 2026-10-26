import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyNomeUsuario = 'key_nome_usuario';
  static const String _keyModoEscuro = 'key_modo_escuro';
  static const String _keyUltimoAcesso = 'key_ultimo_acesso';

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

  Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}