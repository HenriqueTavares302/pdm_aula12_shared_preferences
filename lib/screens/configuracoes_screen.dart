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

  static const String _nomePadrao = 'Usuário Convidado';

  bool _modoEscuro = false;
  bool _carregando = true;
  String? _ultimoAcesso;
  List<Map<String, dynamic>> _historico = [];

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
    final historico = await _service.obterHistorico();

    await _service.registrarAcesso();

    if (!mounted) return;

    setState(() {
      _nomeController.text = nome;
      _modoEscuro = modoEscuro;
      _ultimoAcesso = ultimoAcesso;
      _historico = historico;
      _carregando = false;
    });
  }

  Future<void> _salvarPreferencias() async {
    await _service.salvarNomeUsuario(_nomeController.text);
    await _service.salvarModoEscuro(_modoEscuro);
    await _service.adicionarAoHistorico(_nomeController.text, _modoEscuro);

    final historico = await _service.obterHistorico();

    widget.onTemaAlterado(_modoEscuro);

    if (!mounted) return;

    setState(() => _historico = historico);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferências salvas com sucesso!')),
    );
  }

  Future<void> _confirmarRedefinicao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir padrões'),
        content: const Text(
          'Todas as preferências salvas neste dispositivo serão apagadas. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      await _redefinirPadroes();
    }
  }

  Future<void> _redefinirPadroes() async {
    await _service.limparTudo();
    await _service.registrarAcesso();

    widget.onTemaAlterado(false);

    if (!mounted) return;

    setState(() {
      _nomeController.text = _nomePadrao;
      _modoEscuro = false;
      _ultimoAcesso = null;
      _historico = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferências redefinidas para o padrão')),
    );
  }

  String _formatarData(String bruto) {
    final data = DateTime.tryParse(bruto);
    if (data == null) return bruto;

    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
        'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
  }

  Widget _secaoHistorico() {
    if (_historico.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma alteração registrada ainda.',
            style: TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _historico.length,
      itemBuilder: (context, index) {
        final registro = _historico[index];
        final escuro = registro['modoEscuro'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: Icon(escuro ? Icons.dark_mode : Icons.light_mode, size: 20),
            title: Text(
              registro['nome']?.toString() ?? '',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatarData(registro['data']?.toString() ?? ''),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Histórico de alterações (${_historico.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _secaoHistorico()),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarPreferencias,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmarRedefinicao,
                icon: const Icon(Icons.restore),
                label: const Text('Redefinir Padrões'),
              ),
            ),
            const SizedBox(height: 12),
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