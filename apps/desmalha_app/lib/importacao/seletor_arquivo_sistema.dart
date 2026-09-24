/// [SeletorDeArquivo] sobre o seletor do sistema (`file_selector`; no
/// Android, o Storage Access Framework — sem permissão de armazenamento).
///
/// O seletor do Android filtra por MIME, nunca por extensão, e o Android
/// não conhece `.ofx`: o arquivo entra no índice como
/// `application/octet-stream` (medido no emulador, 24/09/2026). Por isso o
/// filtro é a lista de MIMEs com que OFX e CSV CHEGAM de fato — do índice de
/// mídia, do download do navegador e do app do banco. Some imagem, PDF,
/// vídeo e documento; arquivo "sem tipo" ainda aparece, porque é assim que o
/// OFX chega. Quem decide o formato, depois de escolhido, é o conteúdo
/// (`detectarFormatoExtrato`).
///
/// O seletor abre na pasta Download, lida na hora. Aberto em "Recentes",
/// ele mostrava a lista do índice de mídia, que num Samsung pode não ter o
/// arquivo que acabou de chegar (relato do owner no S23, 24/09/2026).
library;

import 'package:file_selector/file_selector.dart';

import 'controlador_importacao.dart';

/// MIMEs com que um extrato OFX ou CSV chega ao seletor do Android.
const List<String> mimesDeExtrato = [
  // OFX: o Android não tem MIME para .ofx — cai em octet-stream. Os demais
  // são os que bancos e navegadores declaram no download.
  'application/octet-stream',
  'application/x-ofx',
  'application/ofx',
  'application/vnd.intu.qfx',
  'text/x-ofx',
  // CSV: o índice de mídia usa text/comma-separated-values; download de
  // navegador costuma vir como text/csv, e alguns bancos servem o CSV como
  // planilha do Excel.
  'text/csv',
  'text/comma-separated-values',
  'application/csv',
  'application/vnd.ms-excel',
  // Banco que entrega extrato como texto simples.
  'text/plain',
];

/// A pasta Download no armazenamento principal, como documento do SAF.
const String pastaDownloadNoAndroid =
    'content://com.android.externalstorage.documents/document/primary%3ADownload';

class SeletorDeArquivoDoSistema implements SeletorDeArquivo {
  const SeletorDeArquivoDoSistema();

  @override
  Future<ArquivoSelecionado?> escolher() async {
    final arquivo = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Extrato OFX ou CSV', mimeTypes: mimesDeExtrato),
      ],
      initialDirectory: pastaDownloadNoAndroid,
    );
    if (arquivo == null) return null;
    return ArquivoSelecionado(
      nome: arquivo.name,
      bytes: await arquivo.readAsBytes(),
    );
  }
}
