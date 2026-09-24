import 'package:desmalha_app/onboarding/porta_aceite.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';
import 'documentos_falsos.dart';

void main() {
  group('documentos legais', () {
    test(
      'nada publicado: pendência visível, nenhum aceite a registrar',
      () async {
        final aceite = AceiteFalso();
        final c = controladorOnboardingFalso(aceite: aceite);
        await c.carregar();
        expect(c.naoPublicados, [
          TipoDocumentoLegal.termosUso,
          TipoDocumentoLegal.politicaPrivacidade,
        ]);
        expect(c.aceitesPendentes, isEmpty);
        expect(c.precisaAceite, isFalse);
        expect(c.bloqueadoSemPublicacao, isFalse); // build de desenvolvimento
        await c.aceitarPendentes();
        expect(aceite.registrados, isEmpty, reason: 'aceite sem texto: nunca');
      },
    );

    test('release sem publicação: bloqueado', () async {
      final c = controladorOnboardingFalso(permiteSeguirSemTermos: false);
      await c.carregar();
      expect(c.bloqueadoSemPublicacao, isTrue);
    });

    test('publicados: registra no servidor, depois o espelho local', () async {
      final aceite = AceiteFalso();
      final repo = RepositorioOnboardingMemoria();
      final c = controladorOnboardingFalso(
        aceite: aceite,
        repositorio: repo,
        catalogo: catalogoComDocumentos(
          termos: '2026-09-v1',
          politica: '2026-09-v2',
        ),
      );
      await c.carregar();
      expect(c.naoPublicados, isEmpty);
      expect(c.aceitesPendentes.map((d) => d.versao), [
        '2026-09-v1',
        '2026-09-v2',
      ]);
      await c.aceitarPendentes();
      expect(aceite.registrados, [
        ('termos_uso', '2026-09-v1'),
        ('politica_privacidade', '2026-09-v2'),
      ]);
      expect(repo.aceites, {
        ('termos_uso', '2026-09-v1'),
        ('politica_privacidade', '2026-09-v2'),
      });
      expect(c.precisaAceite, isFalse);
    });

    test('servidor recusa: nada no espelho local, segue pendente', () async {
      final repo = RepositorioOnboardingMemoria();
      final c = controladorOnboardingFalso(
        aceite: AceiteFalso(falha: const FalhaAceite('fora do ar')),
        repositorio: repo,
        catalogo: catalogoComDocumentos(
          termos: '2026-09-v1',
          politica: '2026-09-v1',
        ),
      );
      await c.carregar();
      await expectLater(c.aceitarPendentes(), throwsA(isA<FalhaAceite>()));
      expect(repo.aceites, isEmpty);
      expect(c.aceitesPendentes, hasLength(2));
    });

    test(
      'versão nova publicada depois do onboarding volta a pedir aceite',
      () async {
        final repo = RepositorioOnboardingMemoria()
          ..aceites.addAll({
            ('termos_uso', '2026-09-v1'),
            ('politica_privacidade', '2026-09-v1'),
          });
        final c = controladorOnboardingFalso(
          concluido: true,
          repositorio: repo,
          catalogo: catalogoComDocumentos(
            termos: '2026-10-v1',
            politica: '2026-09-v1',
          ),
        );
        await c.carregar();
        expect(c.precisaOnboarding, isFalse);
        expect(c.precisaAceite, isTrue);
        expect(c.aceitesPendentes.single.versao, '2026-10-v1');
      },
    );
  });

  group('seus dados', () {
    test('CPF inválido não salva e diz o motivo', () async {
      final repo = RepositorioOnboardingMemoria();
      final c = controladorOnboardingFalso(repositorio: repo);
      await c.carregar();
      expect(
        await c.salvarDados(nome: 'Ana Souza', cpf: '529.982.247-24'),
        contains('CPF inválido'),
      );
      expect(
        await c.salvarDados(nome: ' ', cpf: '52998224725'),
        'Informe seu nome.',
      );
      expect(repo.perfil, isNull);
    });

    test('salva só dígitos e nome sem espaços sobrando', () async {
      final repo = RepositorioOnboardingMemoria();
      final c = controladorOnboardingFalso(repositorio: repo);
      await c.carregar();
      expect(
        await c.salvarDados(nome: '  Ana   Souza ', cpf: '529.982.247-25'),
        isNull,
      );
      expect(repo.perfil!.nome, 'Ana Souza');
      expect(repo.perfil!.cpf, '52998224725');
      expect(
        repo.perfil!.usuarioRemotoId,
        '00000000-0000-4000-8000-00000000000a',
      );
      expect(c.precisaOnboarding, isTrue);
    });

    test('concluir sem perfil salvo falha alto', () async {
      final c = controladorOnboardingFalso();
      await c.carregar();
      await expectLater(c.concluir(), throwsStateError);
      expect(c.precisaOnboarding, isTrue);
    });

    test('concluir com perfil encerra o onboarding', () async {
      final c = controladorOnboardingFalso();
      await c.carregar();
      await c.salvarDados(nome: 'Ana', cpf: '52998224725');
      await c.concluir();
      expect(c.precisaOnboarding, isFalse);
    });
  });
}
