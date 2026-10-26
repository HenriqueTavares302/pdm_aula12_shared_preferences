import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ConfiguracoesScreen extends StatefulWidget {
  final Function(bool) onTemaAlterado;

  const ConfiguracoesScreen({super.key, required this.onTemaAlterado});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _service = PreferencesService();
  final _nomeController = TextEditingController();

  bool _modoEscuro = false;
  bool _carregando = true;
  String? _ultimoAcesso;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferencias() async {
    final nome = await _service.obterNomeUsuario();
    final modoEscuro = await _service.obterModoEscuro();
    final ultimoAcesso = await _service.obterUltimoAcesso();

    await _service.registrarAcesso();

    if (!mounted) return;

    setState(() {
      _nomeController.text = nome;
      _modoEscuro = modoEscuro;
      _ultimoAcesso = ultimoAcesso;
      _carregando = false;
    });
  }

  Future<void> _salvarPreferencias() async {
    await _service.salvarNomeUsuario(_nomeController.text);
    await _service.salvarModoEscuro(_modoEscuro);

    widget.onTemaAlterado(_modoEscuro);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências salvas com sucesso!')),
      );
    }
  }

  String _formatarData(String bruto) {
    final data = DateTime.tryParse(bruto);
    if (data == null) return bruto;

    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
        'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações & Perfil'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativar Modo Escuro'),
              subtitle: const Text('Persiste o tema visual selecionado no disco'),
              value: _modoEscuro,
              onChanged: (valor) => setState(() => _modoEscuro = valor),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarPreferencias,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 6),
                Text(
                  _ultimoAcesso == null
                      ? 'Primeiro acesso neste dispositivo'
                      : 'Último acesso: ${_formatarData(_ultimoAcesso!)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}