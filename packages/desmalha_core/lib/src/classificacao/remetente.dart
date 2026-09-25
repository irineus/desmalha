/// Quem mandou o dinheiro — a chave que liga os lançamentos de um mesmo
/// pagador (decisão 3 do owner, 25/09/2026).
///
/// Sem documento, a chave é o NOME extraído da descrição do extrato e
/// normalizado: maiúsculas, sem acento, sem o vocabulário da operação
/// (`PIX RECEBIDO`, `TED`, `DOC`...), sem data ou dígito colado e sem o
/// trecho do banco (`NU PAGAMENTOS - IP`). Com CPF ou CNPJ informado pelo
/// usuário, o documento vira a chave forte — une as grafias do mesmo
/// pagador e separa homônimos.
///
/// A segmentação é a do anonimizador (`validacao/anonimizador.dart`), pelo
/// mesmo motivo: separador sem espaço é a norma no Itaú e no Bradesco
/// (`PIX*CARLOS`, `SHIRLEI06/08` com a data do MEMO truncado colada), e
/// quebrar só por espaço deixaria o nome preso ao lixo em volta.
library;

import '../darf/documento_darf.dart' show cpfValido;

/// A chave de nome do remetente em [descricao], ou `null` se nela não há
/// nome (tarifa, rendimento, "PIX RECEBIDO" sem remetente).
///
/// Com [nomeContraparte] (o `<NAME>` do OFX ou a coluna de nome do CSV),
/// ele tem precedência: é o campo que o banco declara como nome.
String? chaveDoRemetente(String descricao, {String? nomeContraparte}) {
  if (nomeContraparte != null) {
    final doNome = _primeiroNome(nomeContraparte);
    if (doNome != null) return doNome;
  }
  return _primeiroNome(descricao);
}

/// CNPJ com 14 dígitos e os dois verificadores certos. Aceita máscara.
bool cnpjValido(String cnpj) {
  final d = cnpj.replaceAll(RegExp(r'\D'), '');
  if (d.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;
  int digito(String base, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < pesos.length; i++) {
      soma += int.parse(base[i]) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  const p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  final d1 = digito(d, p1);
  final d2 = digito('${d.substring(0, 12)}$d1', p2);
  return d.endsWith('$d1$d2');
}

/// O documento de um pagador, só dígitos, se for CPF ou CNPJ válido.
({String digitos, bool ehCnpj})? documentoDoPagador(String texto) {
  final d = texto.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11 && cpfValido(d)) return (digitos: d, ehCnpj: false);
  if (d.length == 14 && cnpjValido(d)) return (digitos: d, ehCnpj: true);
  return null;
}

// ── Extração ───────────────────────────────────────────────────────────

String? _primeiroNome(String texto) {
  // Trechos: letras unidas por espaço simples ou pontuação "de nome"
  // (& . ' ,). Dígito, separador estrutural ou espaço duplo quebram.
  final trechos = <List<String>>[];
  var atual = <String>[];
  var palavra = StringBuffer();
  var espacosSeguidos = 0;

  void fecharPalavra() {
    if (palavra.isEmpty) return;
    atual.add(palavra.toString());
    palavra = StringBuffer();
  }

  void fecharTrecho() {
    fecharPalavra();
    if (atual.isNotEmpty) trechos.add(atual);
    atual = <String>[];
  }

  for (final letra in _semAcentos(texto.toUpperCase()).split('')) {
    final u = letra.codeUnitAt(0);
    if (u >= 0x41 && u <= 0x5A) {
      palavra.write(letra);
      espacosSeguidos = 0;
    } else if (letra == ' ') {
      fecharPalavra();
      if (++espacosSeguidos >= 2) fecharTrecho();
    } else if (_pontuacaoDeNome.contains(letra)) {
      fecharPalavra();
      espacosSeguidos = 0;
    } else {
      // dígito, separador estrutural ou qualquer outro símbolo
      fecharTrecho();
      espacosSeguidos = 0;
    }
  }
  fecharTrecho();

  for (final trecho in trechos) {
    final nome = [
      for (final p in trecho)
        if (p.length >= 2 && !_vocabularioDaOperacao.contains(p)) p,
    ];
    // Conectivo não abre nem fecha nome ("DE JOAO" → "JOAO").
    while (nome.isNotEmpty && _conectivos.contains(nome.first)) {
      nome.removeAt(0);
    }
    while (nome.isNotEmpty && _conectivos.contains(nome.last)) {
      nome.removeLast();
    }
    if (nome.isEmpty) continue;
    if (nome.every((p) => _nomeDeBanco.contains(p) || _conectivos.contains(p))) {
      continue;
    }
    return nome.join(' ');
  }
  return null;
}

const _pontuacaoDeNome = {'&', '.', "'", ',', '´', '`'};

const _conectivos = {'DA', 'DE', 'DO', 'DAS', 'DOS', 'E'};

/// Vocabulário da OPERAÇÃO (não do pagador) — o do anonimizador, em
/// maiúsculas e sem acento, mais os rótulos de operação dos bancos.
const _vocabularioDaOperacao = {
  'PIX', 'TED', 'DOC', 'TEF', 'TRANSFERENCIA', 'TRANSF', 'TRANS', 'RECEBIDA',
  'RECEBIDO', 'RECEB', 'REC', 'ENVIADA', 'ENVIADO', 'COMPRA', 'CARTAO',
  'DEBITO', 'CREDITO', 'CRED', 'DEB', 'PAGAMENTO', 'PAGTO', 'PGTO', 'BOLETO',
  'TARIFA', 'SAQUE', 'DEPOSITO', 'DEP', 'RENDIMENTO', 'APLICACAO', 'RESGATE',
  'SALDO', 'ANTERIOR', 'JUROS', 'IOF', 'ESTORNO', 'DEVOLUCAO', 'LIQUIDACAO',
  'COBRANCA', 'CELULAR', 'CONTA', 'CORRENTE', 'POUPANCA', 'AGENCIA', 'AG',
  'CC', 'TITULAR', 'MESMA', 'OUTRA', 'TITULARIDADE', 'PELO', 'PELA', 'VIA',
  'EM', 'NO', 'NA', 'COM', 'PARA', 'POR', 'QR', 'CODE', 'INTERNET', 'MOBILE',
  'APP', 'AGENDADA', 'AGENDADO', 'REMETENTE', 'PAGADOR', 'ORIGEM', 'CPF',
  'CNPJ', 'CHAVE', 'ALEATORIA', 'INSTANTANEO', 'INSTANTANEA', 'SPI',
  'PACOTE', 'SERVICO', 'SERVICOS', 'MENSALIDADE', 'ASSINATURA', 'PARCELA',
  'REFERENTE', 'REF', 'VALOR', 'DATA', 'DOCTO', 'DOCUMENTO', 'HISTORICO',
};

/// Tokens de nome de instituição: um trecho feito só deles é o banco do
/// pagador (`NU PAGAMENTOS - IP`), não o pagador.
const _nomeDeBanco = {
  'NU', 'NUBANK', 'PAGAMENTOS', 'IP', 'SA', 'ITAU', 'UNIBANCO', 'BRADESCO',
  'SANTANDER', 'CAIXA', 'ECONOMICA', 'FEDERAL', 'CEF', 'BCO', 'BANCO', 'BB',
  'BRASIL', 'INTER', 'SICOOB', 'SICREDI', 'PICPAY', 'MERCADO', 'PAGO',
  'PAGSEGURO', 'PAGBANK', 'STONE', 'BANRISUL', 'BTG', 'PACTUAL', 'ORIGINAL',
  'NEON', 'AGIBANK', 'SAFRA', 'MULTIPLO', 'INSTITUICAO', 'COOPERATIVA',
  'CREDITO', 'LTDA', 'SCD', 'SCFI',
};

String _semAcentos(String texto) {
  const mapa = {
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
    'Ç': 'C', 'Ñ': 'N',
  };
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    buffer.write(mapa[texto[i]] ?? texto[i]);
  }
  return buffer.toString();
}
