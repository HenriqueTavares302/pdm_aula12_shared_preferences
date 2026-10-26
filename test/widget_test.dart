import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdm_aula12_shared_preferences/screens/configuracoes_screen.dart';
import 'package:pdm_aula12_shared_preferences/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget montarTela({void Function(bool)? onTema}) {
    return MaterialApp(
      home: ConfiguracoesScreen(onTemaAlterado: onTema ?? (_) {}),
    );
  }

  group('PreferencesService — valores padrao', () {
    test('devolve nome padrao quando nada foi salvo', () async {
      final service = PreferencesService();

      expect(await service.obterNomeUsuario(), 'Usuário Convidado');
    });

    test('devolve modo escuro desligado quando nada foi salvo', () async {
      final service = PreferencesService();

      expect(await service.obterModoEscuro(), isFalse);
    });

    test('devolve null para ultimo acesso antes do primeiro registro', () async {
      final service = PreferencesService();

      expect(await service.obterUltimoAcesso(), isNull);
    });

    test('devolve historico vazio quando nada foi salvo', () async {
      final service = PreferencesService();

      expect(await service.obterHistorico(), isEmpty);
    });
  });

  group('PreferencesService — escrita e leitura', () {
    test('persiste e recupera o nome do usuario', () async {
      final service = PreferencesService();

      await service.salvarNomeUsuario('João Gabriel');

      expect(await service.obterNomeUsuario(), 'João Gabriel');
    });

    test('persiste e recupera o modo escuro', () async {
      final service = PreferencesService();

      await service.salvarModoEscuro(true);

      expect(await service.obterModoEscuro(), isTrue);
    });

    test('registra uma data valida no ultimo acesso', () async {
      final service = PreferencesService();

      await service.registrarAcesso();
      final bruto = await service.obterUltimoAcesso();

      expect(bruto, isNotNull);
      expect(DateTime.tryParse(bruto!), isNotNull);
    });

    test('limparTudo apaga todas as chaves gravadas', () async {
      final service = PreferencesService();

      await service.salvarNomeUsuario('Teste');
      await service.salvarModoEscuro(true);
      await service.adicionarAoHistorico('Teste', true);

      await service.limparTudo();

      expect(await service.obterNomeUsuario(), 'Usuário Convidado');
      expect(await service.obterModoEscuro(), isFalse);
      expect(await service.obterHistorico(), isEmpty);
    });
  });

  group('PreferencesService — historico em JSON', () {
    test('adiciona um registro preservando os tipos apos serializar', () async {
      final service = PreferencesService();

      await service.adicionarAoHistorico('Ana', true);
      final historico = await service.obterHistorico();

      expect(historico.length, 1);
      expect(historico.first['nome'], 'Ana');
      expect(historico.first['modoEscuro'], isTrue);
      expect(DateTime.tryParse(historico.first['data']), isNotNull);
    });

    test('insere o registro mais recente no topo da lista', () async {
      final service = PreferencesService();

      await service.adicionarAoHistorico('Primeiro', false);
      await service.adicionarAoHistorico('Segundo', true);

      final historico = await service.obterHistorico();

      expect(historico.length, 2);
      expect(historico.first['nome'], 'Segundo');
      expect(historico.last['nome'], 'Primeiro');
    });

    test('limita o historico a dez registros', () async {
      final service = PreferencesService();

      for (var i = 1; i <= 15; i++) {
        await service.adicionarAoHistorico('Registro $i', false);
      }

      final historico = await service.obterHistorico();

      expect(historico.length, 10);
      expect(historico.first['nome'], 'Registro 15');
      expect(historico.last['nome'], 'Registro 6');
    });

    test('devolve lista vazia quando o JSON salvo esta corrompido', () async {
      SharedPreferences.setMockInitialValues({
        'key_historico': 'isto nao e json valido',
      });

      final service = PreferencesService();

      expect(await service.obterHistorico(), isEmpty);
    });
  });

  group('ConfiguracoesScreen', () {
    testWidgets('exibe o indicador antes de carregar as preferencias',
        (tester) async {
      await tester.pumpWidget(montarTela());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('preenche o campo e o switch com os valores salvos no disco',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'key_nome_usuario': 'Maria',
        'key_modo_escuro': true,
      });

      await tester.pumpWidget(montarTela());
      await tester.pumpAndSettle();

      final campo = tester.widget<TextField>(find.byType(TextField));
      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));

      expect(campo.controller!.text, 'Maria');
      expect(switchTile.value, isTrue);
    });

    testWidgets('exibe o texto de primeiro acesso quando nao ha registro',
        (tester) async {
      await tester.pumpWidget(montarTela());
      await tester.pumpAndSettle();

      expect(find.text('Primeiro acesso neste dispositivo'), findsOneWidget);
    });

    testWidgets('salvar persiste os dados e notifica a mudanca de tema',
        (tester) async {
      bool? temaRecebido;

      await tester.pumpWidget(montarTela(onTema: (valor) => temaRecebido = valor));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Carlos');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(temaRecebido, isTrue);
      expect(find.text('Preferências salvas com sucesso!'), findsOneWidget);
      expect(await PreferencesService().obterNomeUsuario(), 'Carlos');
    });

    testWidgets('salvar adiciona o registro ao historico exibido',
        (tester) async {
      await tester.pumpWidget(montarTela());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma alteração registrada ainda.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Paula');
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(find.text('Histórico de alterações (1)'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('Paula')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('redefinir pede confirmacao e restaura os valores padrao',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'key_nome_usuario': 'Roberto',
        'key_modo_escuro': true,
      });

      bool? temaRecebido;

      await tester.pumpWidget(montarTela(onTema: (valor) => temaRecebido = valor));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Redefinir Padrões'));
      await tester.pumpAndSettle();

      expect(find.text('Redefinir padrões'), findsOneWidget);

      await tester.tap(find.text('Redefinir').last);
      await tester.pumpAndSettle();

      final campo = tester.widget<TextField>(find.byType(TextField));
      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));

      expect(campo.controller!.text, 'Usuário Convidado');
      expect(switchTile.value, isFalse);
      expect(temaRecebido, isFalse);
      expect(await PreferencesService().obterNomeUsuario(), 'Usuário Convidado');
    });

    testWidgets('cancelar a redefinicao mantem os valores atuais',
        (tester) async {
      SharedPreferences.setMockInitialValues({'key_nome_usuario': 'Beatriz'});

      await tester.pumpWidget(montarTela());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Redefinir Padrões'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final campo = tester.widget<TextField>(find.byType(TextField));

      expect(campo.controller!.text, 'Beatriz');
    });
  });
}