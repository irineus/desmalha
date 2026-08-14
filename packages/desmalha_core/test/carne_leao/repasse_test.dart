import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Cenário 11 da spec: árvore de decisão de repasse e custas, com os dois
/// ramos do CPF do profissional e o trânsito neutro no CPF do cliente.
void main() {
  group('classificarRepasse', () {
    test('comprovante no CPF do cliente é trânsito neutro', () {
      expect(
        classificarRepasse(comprovanteNoCpfDoCliente: true),
        TratamentoRepasse.transitoNeutro,
      );
    });

    test('CPF do profissional + custo essencial vira receita e despesa', () {
      expect(
        classificarRepasse(
          comprovanteNoCpfDoCliente: false,
          custoEssencialAoServico: true,
        ),
        TratamentoRepasse.receitaComDespesa,
      );
    });

    test('CPF do profissional + custo não essencial é só receita', () {
      expect(
        classificarRepasse(
          comprovanteNoCpfDoCliente: false,
          custoEssencialAoServico: false,
        ),
        TratamentoRepasse.somenteReceita,
      );
    });

    test('CPF do profissional sem resposta de essencialidade falha alto', () {
      // A segunda pergunta da UX é obrigatória — o motor não decide
      // dedutibilidade sozinho pelo usuário.
      expect(
        () => classificarRepasse(comprovanteNoCpfDoCliente: false),
        throwsArgumentError,
      );
    });
  });
}
