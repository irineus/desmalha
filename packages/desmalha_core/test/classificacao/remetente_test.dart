import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('chaveDoRemetente — formatos reais dos bancos', () {
    const casos = {
      // OFX (MEMO) das fixtures sintéticas
      'PIX RECEBIDO JOÃO DA SILVA': 'JOAO DA SILVA',
      'TED RECEBIDA CLÍNICA SÃO JOSÉ': 'CLINICA SAO JOSE',
      // o parser já decodificou o &amp; do OFX
      'PIX RECEBIDO SOUZA & FILHOS': 'SOUZA FILHOS',
      // Nubank CSV: nome entre " - ", CPF mascarado e o banco no fim
      'Transferência recebida pelo Pix - MARIA DA SILVA - •••.123.456-•• - '
          'NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 12345-6':
          'MARIA DA SILVA',
      'Transferência recebida pelo Pix - ANA': 'ANA',
      // Itaú: separador sem espaço e data do MEMO truncado colada
      'PIX TRANSF SHIRLEI06/08': 'SHIRLEI',
      'PIX*CARLOS': 'CARLOS',
      'DOC.RENATA MOURA': 'RENATA MOURA',
      'TED 237.0001 JOSE ALVES': 'JOSE ALVES',
      // Inicial solta do MEMO cortado não entra na chave
      'PIX RECEBIDO MARIA S06/08': 'MARIA',
      // Espaço duplo separa trechos: o banco não é o pagador
      'PIX RECEBIDO  BANCO DO BRASIL': null,
      'PIX RECEBIDO PEDRO  BANCO INTER': 'PEDRO',
      // Conectivo não abre nem fecha nome
      'PIX DE JOAO': 'JOAO',
    };
    for (final MapEntry(key: descricao, value: chave) in casos.entries) {
      test('"$descricao" → ${chave ?? 'sem nome'}', () {
        expect(chaveDoRemetente(descricao), chave);
      });
    }

    test('sem nome na descrição: null (tarifa, rendimento, Pix sem remetente)',
        () {
      expect(chaveDoRemetente('TARIFA PACOTE SERVICOS'), isNull);
      expect(chaveDoRemetente('RENDIMENTO POUPANCA'), isNull);
      expect(chaveDoRemetente('PIX RECEBIDO'), isNull);
      expect(chaveDoRemetente('12/08 1234'), isNull);
    });

    test('grafias do mesmo nome caem na mesma chave', () {
      expect(chaveDoRemetente('pix recebido joão da silva'),
          chaveDoRemetente('PIX RECEBIDO JOAO DA SILVA'));
      expect(chaveDoRemetente('PIX-JOAO DA SILVA'),
          chaveDoRemetente('Transferência recebida pelo Pix - JOÃO DA SILVA'));
    });

    test('o nome declarado pelo banco (OFX <NAME>) tem precedência', () {
      expect(
        chaveDoRemetente('PIX RECEBIDO 0000123',
            nomeContraparte: 'Ana Pereira'),
        'ANA PEREIRA',
      );
      expect(
        chaveDoRemetente('PIX RECEBIDO ANA', nomeContraparte: '0000'),
        'ANA',
        reason: 'nome declarado vazio de letras cai para a descrição',
      );
    });
  });

  group('documento do pagador', () {
    test('CNPJ válido, com e sem máscara', () {
      expect(cnpjValido('11.222.333/0001-81'), isTrue);
      expect(cnpjValido('11222333000181'), isTrue);
      expect(cnpjValido('11222333000182'), isFalse);
      expect(cnpjValido('00000000000000'), isFalse);
      expect(cnpjValido('1122233300018'), isFalse);
    });

    test('documentoDoPagador distingue CPF de CNPJ e recusa inválido', () {
      expect(documentoDoPagador('529.982.247-25'),
          (digitos: '52998224725', ehCnpj: false));
      expect(documentoDoPagador('11.222.333/0001-81'),
          (digitos: '11222333000181', ehCnpj: true));
      expect(documentoDoPagador('529.982.247-24'), isNull);
      expect(documentoDoPagador('abc'), isNull);
    });
  });
}
