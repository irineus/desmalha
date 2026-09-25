import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('conteúdo real do repositório', () {
    // A mesma varredura do gerador de seed — convenção do publicador
    // (tool/publicar_catalogo.ts): catalogo/<tipo>/<id>.json + perfis/.
    final itens = itensDoCatalogoNoRepositorio('.');
    final catalogo = Catalogo.fromItens(itens);

    test('carrega inteiro, sem tipo desconhecido e sem item vazio', () {
      expect(catalogo.tiposIgnorados, isEmpty,
          reason: 'diretório novo em catalogo/ exige tipo conhecido pelo '
              'app OU decisão explícita de servi-lo só a apps futuros');
      expect(catalogo.tabelasIrpf, isNotEmpty);
      expect(catalogo.feriadosPorAno, isNotEmpty);
      expect(catalogo.perfisCsv, hasLength(3),
          reason: 'Nubank, Inter e BB — os perfis de referência de perfis/');
    });

    test('rubricas: a trava de 20% é a lista fechada das rodadas 4 e 4b', () {
      final residencia = {
        for (final r in catalogo.rubricas)
          if (r.travaResidencia) r.id,
      };
      expect(residencia, {
        'aluguel-residencia',
        'condominio-residencia',
        'energia-residencia',
        'agua-residencia',
        'iptu-residencia',
        'gas-residencia',
        'taxas-municipais-residencia',
        'internet-residencia',
        'telefone-residencia',
      });
      // P4 (rodada 4): IPTU R$ 2.400,00 → R$ 480,00 dedutíveis.
      final iptu = catalogo.rubricaPorId('iptu-residencia')!;
      expect(iptu.despesa(240000).dedutivelCentavos, 48000);
      // P4 (rodada 4b): internet de casa R$ 150,00 → R$ 30,00.
      final internet = catalogo.rubricaPorId('internet-residencia')!;
      expect(internet.despesa(15000).dedutivelCentavos, 3000);
    });

    test('rubricas: linha exclusiva deduz 100% e pede a declaração', () {
      final linha = catalogo.rubricaPorId('linha-exclusiva-atividade')!;
      expect(linha.exigeDeclaracaoExclusividade, isTrue);
      expect(linha.travaResidencia, isFalse);
      // P4 (rodada 4b): linha exclusiva R$ 60,00 → R$ 60,00.
      expect(linha.despesa(6000).dedutivelCentavos, 6000);
      expect(linha.orientacao, contains('CPF'));
      final comDeclaracao = [
        for (final r in catalogo.rubricas)
          if (r.exigeDeclaracaoExclusividade) r.id,
      ];
      expect(comDeclaracao, ['linha-exclusiva-atividade']);
    });

    test('rubricas vedadas: registram o gasto e deduzem zero', () {
      final vedadas = {
        for (final r in catalogo.rubricas)
          if (!r.dedutivel) r.id,
      };
      expect(vedadas, {
        'transporte-combustivel',
        'formacao-graduacao-pos',
        'equipamento-duravel',
      });
      for (final id in vedadas) {
        final rubrica = catalogo.rubricaPorId(id)!;
        expect(rubrica.despesa(100000).dedutivelCentavos, 0, reason: id);
      }
    });

    test('rubricas saem em ordem e sem ordem repetida', () {
      final ordens = [for (final r in catalogo.rubricas) r.ordem];
      expect(ordens, orderedEquals([...ordens]..sort()));
      expect(ordens.toSet(), hasLength(ordens.length));
    });

    test('profissões: saúde pede CPF do pagador e do beneficiário', () {
      final saude = {
        for (final p in catalogo.profissoes)
          if (p.saude) p.id,
      };
      // Rodada 2, item 2: médicos, dentistas, psicólogos, fisioterapeutas,
      // TO e fono.
      expect(saude, {
        'medico',
        'dentista',
        'psicologo',
        'fisioterapeuta',
        'terapeuta-ocupacional',
        'fonoaudiologo',
      });
      // Demais regulamentadas: só o CPF de quem pagou.
      final soPagador = {
        for (final p in catalogo.profissoes)
          if (p.regulamentada && !p.saude) p.id,
      };
      expect(soPagador, {'nutricionista', 'advogado'});
      // Rodada 2, item 4: MEI vedado a psicólogo, fisio, nutricionista e
      // advogado; permitido a fotógrafo e professor particular.
      const vedadoMei = [
        'psicologo',
        'fisioterapeuta',
        'nutricionista',
        'advogado',
      ];
      for (final id in vedadoMei) {
        expect(catalogo.profissaoPorId(id)!.meiPermitido, isFalse, reason: id);
      }
      for (final id in ['fotografo', 'professor-particular']) {
        final profissao = catalogo.profissaoPorId(id)!;
        expect(profissao.meiPermitido, isTrue, reason: id);
        expect(profissao.regulamentada, isFalse, reason: id);
      }
    });

    test('nome de arquivo = id do conteúdo (Catalogo já reprova divergir)',
        () {
      // Catalogo.fromItens lança se o id da linha difere do id do conteúdo;
      // chegar aqui prova a propriedade. A âncora abaixo garante que ela não
      // passou por vacuidade.
      expect(itens, isNotEmpty);
    });

    test('a tabela do IRPF bate com a dos cenários table-driven', () {
      final cenarios = jsonDecode(
        File('cenarios/cenarios_carne_leao.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final tabelasCenarios = [
        for (final t in cenarios['tabelas'] as List<Object?>)
          TabelaIrpf.fromJson(t as Map<String, Object?>),
      ];
      // Compara pela forma canônica (toJson do objeto parseado): campos
      // extras como "fonte" não contam, valor fiscal conta todo.
      for (final doCenario in tabelasCenarios) {
        final doCatalogo = catalogo.tabelasIrpf
            .where((t) => t.id == doCenario.id)
            .toList();
        expect(doCatalogo, hasLength(1),
            reason: 'tabela ${doCenario.id} dos cenários precisa existir no '
                'catálogo — o motor é provado com ela');
        expect(
          jsonEncode(doCatalogo.single.toJson()),
          jsonEncode(doCenario.toJson()),
          reason: 'catálogo e cenários divergem na tabela ${doCenario.id}: '
              'o app calcularia com uma tabela e o motor seria provado com '
              'outra',
        );
      }
    });

    test('feriados de 2026: os 13 da FEBRABAN mais 31/12 sem expediente', () {
      final feriados = catalogo.feriadosDoAno(2026);
      expect(feriados, hasLength(14));
      expect(
        feriados,
        containsAll(const {
          '2026-01-01', // Confraternização Universal
          '2026-02-16', '2026-02-17', // Carnaval
          '2026-04-03', // Sexta-Feira da Paixão
          '2026-04-21', // Tiradentes
          '2026-05-01', // Dia do Trabalho
          '2026-06-04', // Corpus Christi
          '2026-09-07', // Independência
          '2026-10-12', // Nossa Senhora Aparecida
          '2026-11-02', // Finados
          '2026-11-15', // Proclamação da República (domingo — inofensivo)
          '2026-11-20', // Consciência Negra
          '2026-12-25', // Natal
          '2026-12-31', // sem expediente ao público (FEBRABAN)
        }),
      );
    });

    test('competência nov/2026 vence em 30/12, não em 31/12', () {
      // 31/12/2026 é quinta-feira e NÃO é feriado civil — mas a FEBRABAN não
      // abre agência e manda antecipar tributos. É o caso que a lista de
      // feriados existe para acertar.
      expect(catalogo.vencimentoDarfDe('2026-11'), '2026-12-30');
    });

    test('competência out/2026 vence em 30/11 (segunda, dia útil)', () {
      expect(catalogo.vencimentoDarfDe('2026-10'), '2026-11-30');
    });

    test('ano sem cobertura de feriados falha alto, nunca calcula sem eles',
        () {
      // Competência dez/2026 vence em jan/2027 — e 2027 ainda não foi
      // publicado. Calcular com conjunto vazio devolveria uma data possivelmente
      // errada em silêncio; a rotina anual da Fase 9 publica o ano novo.
      expect(
        () => catalogo.vencimentoDarfDe('2026-12'),
        throwsStateError,
      );
      expect(() => catalogo.feriadosDoAno(2027), throwsStateError);
    });

    test('snapshot: toJson → fromJson preserva o catálogo inteiro', () {
      final snapshot = catalogo.toJson();
      expect(snapshot['formatoVersao'], formatoSnapshotCatalogo);
      final relido = Catalogo.fromJson(
        jsonDecode(jsonEncode(snapshot)) as Map<String, Object?>,
      );
      expect(relido.tabelasIrpf.map((t) => t.id),
          catalogo.tabelasIrpf.map((t) => t.id));
      expect(relido.feriadosDoAno(2026), catalogo.feriadosDoAno(2026));
      expect(relido.perfisCsv.map((p) => p.id),
          catalogo.perfisCsv.map((p) => p.id));
    });
  });

  group('Catalogo.fromItens', () {
    Map<String, Object?> feriados2026({String id = 'feriados-bancarios-2026'}) =>
        {
          'tipo': TipoCatalogo.feriadosBancarios,
          'id': id,
          'conteudo': {
            'id': id,
            'ano': 2026,
            'fonte': 'teste',
            'datas': ['2026-01-01'],
          },
        };

    test('tipo desconhecido é ignorado e listado — app antigo segue de pé',
        () {
      final catalogo = Catalogo.fromItens([
        feriados2026(),
        {
          'tipo': 'simulacao_pf_cnpj',
          'id': 'v1',
          'conteudo': {'qualquer': 'coisa'},
        },
      ]);
      expect(catalogo.tiposIgnorados, ['simulacao_pf_cnpj']);
      expect(catalogo.feriadosPorAno, hasLength(1));
    });

    test('item de tipo desconhecido SOBREVIVE ao round-trip do snapshot', () {
      // O cache local não pode descartar o que o app ainda não entende: o
      // usuário atualiza o app e o cache mutilado esconderia conteúdo já
      // baixado.
      final catalogo = Catalogo.fromItens([
        feriados2026(),
        {
          'tipo': 'simulacao_pf_cnpj',
          'id': 'v1',
          'conteudo': {'qualquer': 'coisa'},
        },
      ]);
      final relido = Catalogo.fromJson(catalogo.toJson());
      expect(relido.tiposIgnorados, ['simulacao_pf_cnpj']);
      expect((relido.toJson()['itens'] as List), hasLength(2));
    });

    test('conteúdo malformado de tipo conhecido falha alto', () {
      expect(
        () => Catalogo.fromItens([
          {
            'tipo': TipoCatalogo.tabelaIrpf,
            'id': 'irpf-quebrada',
            'conteudo': {'id': 'irpf-quebrada', 'faixas': <Object?>[]},
          },
        ]),
        throwsFormatException,
      );
    });

    test('id da linha divergente do id do conteúdo é recusado', () {
      expect(
        () => Catalogo.fromItens([feriados2026()..['id'] = 'outro-id']),
        throwsFormatException,
      );
    });

    test('item repetido é recusado', () {
      expect(
        () => Catalogo.fromItens([feriados2026(), feriados2026()]),
        throwsFormatException,
      );
    });

    test('tabelas IRPF com vigências sobrepostas são recusadas na carga', () {
      // No desenho original do servidor isto era um EXCLUDE de gist; no
      // catálogo genérico a trava vive aqui — e dispara na carga, não só
      // quando alguém consulta a competência ambígua.
      Map<String, Object?> tabela(String id, String inicio, String? fim) => {
            'tipo': TipoCatalogo.tabelaIrpf,
            'id': id,
            'conteudo': {
              'id': id,
              'vigenciaInicio': inicio,
              'vigenciaFim': fim,
              'valorDependenteCentavos': 0,
              'descontoSimplificadoCentavos': 0,
              'faixas': [
                {
                  'limiteSuperiorCentavos': null,
                  'aliquotaPontosBase': 0,
                  'parcelaDeduzirCentavos': 0,
                },
              ],
            },
          };
      expect(
        () => Catalogo.fromItens([
          tabela('irpf-a', '2026-01', null),
          tabela('irpf-b', '2026-06', null),
        ]),
        throwsFormatException,
      );
      // Vigências encostadas, sem sobreposição, passam.
      final ok = Catalogo.fromItens([
        tabela('irpf-a', '2026-01', '2026-05'),
        tabela('irpf-b', '2026-06', null),
      ]);
      expect(ok.tabelaVigentePara('2026-05').id, 'irpf-a');
      expect(ok.tabelaVigentePara('2026-06').id, 'irpf-b');
    });

    test('dois registros de feriados para o mesmo ano são recusados', () {
      expect(
        () => Catalogo.fromItens([
          feriados2026(),
          feriados2026(id: 'feriados-bancarios-2026-bis'),
        ]),
        throwsFormatException,
      );
    });

    test('snapshot de versão futura é recusado por inteiro', () {
      expect(
        () => Catalogo.fromJson({'formatoVersao': 2, 'itens': <Object?>[]}),
        throwsFormatException,
      );
    });
  });

  group('FeriadosBancarios', () {
    Map<String, Object?> base() => {
          'id': 'feriados-bancarios-2026',
          'ano': 2026,
          'fonte': 'teste',
          'datas': ['2026-01-01', '2026-12-25'],
        };

    test('carrega o caso válido', () {
      final f = FeriadosBancarios.fromJson(base());
      expect(f.ano, 2026);
      expect(f.datas, hasLength(2));
    });

    test('data que não existe no calendário é recusada', () {
      expect(
        () => FeriadosBancarios.fromJson(base()..['datas'] = ['2026-02-30']),
        throwsFormatException,
      );
    });

    test('data fora do ano declarado é recusada', () {
      expect(
        () => FeriadosBancarios.fromJson(
            base()..['datas'] = ['2026-01-01', '2027-01-01']),
        throwsFormatException,
      );
    });

    test('datas fora de ordem ou repetidas são recusadas', () {
      expect(
        () => FeriadosBancarios.fromJson(
            base()..['datas'] = ['2026-12-25', '2026-01-01']),
        throwsFormatException,
      );
      expect(
        () => FeriadosBancarios.fromJson(
            base()..['datas'] = ['2026-01-01', '2026-01-01']),
        throwsFormatException,
      );
    });

    test('lista vazia é recusada — ano sem feriado bancário não existe', () {
      expect(
        () => FeriadosBancarios.fromJson(base()..['datas'] = <Object?>[]),
        throwsFormatException,
      );
    });

    test('registro sem fonte é recusado', () {
      expect(
        () => FeriadosBancarios.fromJson(base()..remove('fonte')),
        throwsFormatException,
      );
    });
  });

  group('DocumentoLegal', () {
    const hash =
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
    Map<String, Object?> base({
      String documento = 'termos_uso',
      String versao = '2026-09-v1',
      String? id,
      String publicadoEm = '2026-09-24',
    }) => {
      'id': id ?? DocumentoLegal.idDe(documento, versao),
      'documento': documento,
      'versao': versao,
      'publicado_em': publicadoEm,
      'url': 'https://desmalha.app/termos/$versao',
      'sha256_texto': hash,
      'fonte': 'teste',
    };
    Map<String, Object?> item(Map<String, Object?> conteudo) => {
      'tipo': TipoCatalogo.documentoLegal,
      'id': conteudo['id'],
      'conteudo': conteudo,
    };

    test('carrega pelo catálogo e o id é derivado de documento + versão', () {
      final c = Catalogo.fromItens([item(base())]);
      expect(c.tiposIgnorados, isEmpty);
      expect(c.documentosLegais.single.id, 'termos-uso-2026-09-v1');
      expect(c.documentosLegais.single.sha256Texto, hash);
    });

    test('id escolhido à mão, fora da derivação, é recusado', () {
      // Dois arquivos para a mesma versão com ids diferentes seriam dois
      // textos disputando o mesmo aceite.
      expect(
        () => DocumentoLegal.fromJson(base(id: 'termos-uso-bis')),
        throwsFormatException,
      );
    });

    test('documento desconhecido é recusado', () {
      expect(
        () => DocumentoLegal.fromJson(base(documento: 'contrato')),
        throwsFormatException,
      );
    });

    test('versão fora da convenção YYYY-MM-vN é recusada', () {
      expect(
        () => DocumentoLegal.fromJson(base(versao: 'v0.2')),
        throwsFormatException,
      );
    });

    test('hash que não é SHA-256 hex minúsculo é recusado', () {
      expect(
        () => DocumentoLegal.fromJson(
          base()..['sha256_texto'] = hash.toUpperCase(),
        ),
        throwsFormatException,
      );
      expect(
        () => DocumentoLegal.fromJson(
          base()..['sha256_texto'] = hash.substring(1),
        ),
        throwsFormatException,
      );
    });

    test('url sem https é recusada', () {
      expect(
        () => DocumentoLegal.fromJson(
          base()..['url'] = 'http://desmalha.app/termos',
        ),
        throwsFormatException,
      );
    });

    test('data de publicação inexistente é recusada', () {
      expect(
        () => DocumentoLegal.fromJson(base(publicadoEm: '2026-02-30')),
        throwsFormatException,
      );
    });

    test('sem fonte é recusado', () {
      expect(
        () => DocumentoLegal.fromJson(base()..['fonte'] = ''),
        throwsFormatException,
      );
    });

    test(
      'vigente = a de publicação mais recente; v10 vence v9 no mesmo dia',
      () {
        final c = Catalogo.fromItens([
          item(base(versao: '2026-09-v9')),
          item(base(versao: '2026-09-v10')),
          item(base(versao: '2026-08-v1', publicadoEm: '2026-08-01')),
          item(base(documento: 'politica_privacidade', versao: '2026-07-v1')),
        ]);
        expect(c.documentoLegalVigente('termos_uso')!.versao, '2026-09-v10');
        expect(
          c.documentoLegalVigente('politica_privacidade')!.versao,
          '2026-07-v1',
        );
      },
    );

    test('nada publicado: vigente é nulo, não um documento inventado', () {
      expect(
        Catalogo.fromItens(const []).documentoLegalVigente('termos_uso'),
        isNull,
      );
    });

    test('round-trip do snapshot preserva o documento', () {
      final c = Catalogo.fromItens([item(base())]);
      final relido = Catalogo.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, Object?>,
      );
      expect(
        jsonEncode(relido.documentosLegais.single.toJson()),
        jsonEncode(base()),
      );
    });
  });

  group('Rubrica', () {
    Map<String, Object?> valida() => {
          'id': 'x',
          'nome': 'X',
          'grupo': 'atividade',
          'dedutivel': true,
          'travaResidencia': false,
          'exigeDeclaracaoExclusividade': false,
          'ordem': 1,
          'fonte': 'teste',
        };

    test('carrega o caso válido', () {
      expect(Rubrica.fromJson(valida()).grupo, GrupoRubrica.atividade);
    });

    test('vedada dedutível é recusada', () {
      expect(() => Rubrica.fromJson({...valida(), 'grupo': 'vedada'}),
          throwsFormatException);
    });

    test('vedada sem dizer por quê é recusada', () {
      expect(
        () => Rubrica.fromJson(
            {...valida(), 'grupo': 'vedada', 'dedutivel': false}),
        throwsFormatException,
      );
    });

    test('trava de 20% fora do grupo residência é recusada', () {
      expect(() => Rubrica.fromJson({...valida(), 'travaResidencia': true}),
          throwsFormatException);
      expect(() => Rubrica.fromJson({...valida(), 'grupo': 'residencia'}),
          throwsFormatException);
    });

    test('declaração de exclusividade sem orientação é recusada', () {
      expect(
        () => Rubrica.fromJson(
            {...valida(), 'exigeDeclaracaoExclusividade': true}),
        throwsFormatException,
      );
    });

    test('grupo desconhecido é recusado', () {
      expect(() => Rubrica.fromJson({...valida(), 'grupo': 'outro'}),
          throwsFormatException);
    });
  });

  group('Profissao', () {
    Map<String, Object?> valida() => {
          'id': 'x',
          'nome': 'X',
          'regulamentada': true,
          'saude': true,
          'conselho': 'CRX',
          'meiPermitido': null,
          'fonte': 'teste',
        };

    test('carrega o caso válido', () {
      expect(Profissao.fromJson(valida()).saude, isTrue);
    });

    test('saúde sem ser regulamentada é recusada', () {
      expect(() => Profissao.fromJson({...valida(), 'regulamentada': false}),
          throwsFormatException);
    });

    test('regulamentada sem conselho é recusada', () {
      expect(() => Profissao.fromJson({...valida(), 'conselho': null}),
          throwsFormatException);
    });
  });
}
