/// [SeletorDeArquivo] sobre o seletor do sistema (`file_selector`; no
/// Android, o Storage Access Framework — sem permissão de armazenamento).
///
/// Sem filtro de tipo de propósito: OFX não tem MIME padronizado, e cada
/// banco entrega com um (`application/x-ofx`, `text/plain`,
/// `application/octet-stream`...). Filtrar deixaria o arquivo certo cinza
/// na lista. Quem decide o formato é o conteúdo (`detectarFormatoExtrato`).
library;

import 'package:file_selector/file_selector.dart';

import 'controlador_importacao.dart';

class SeletorDeArquivoDoSistema implements SeletorDeArquivo {
  const SeletorDeArquivoDoSistema();

  @override
  Future<ArquivoSelecionado?> escolher() async {
    final arquivo = await openFile(
      acceptedTypeGroups: const [XTypeGroup(label: 'Extrato OFX ou CSV')],
    );
    if (arquivo == null) return null;
    return ArquivoSelecionado(
      nome: arquivo.name,
      bytes: await arquivo.readAsBytes(),
    );
  }
}
