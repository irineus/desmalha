package com.desmalha.desmalha_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Recebe o extrato que outro app entrega ao Desmalha — "Compartilhar →
 * Desmalha" (ACTION_SEND) ou "Abrir com" (ACTION_VIEW), a partir do Meus
 * Arquivos, do e-mail ou do app do banco — e o repassa ao Dart.
 *
 * Existe porque a busca do seletor do sistema não é do app e falha no
 * Samsung (relato do owner, 24/09/2026); a do Meus Arquivos funciona.
 *
 * O arquivo é lido AQUI, pelo ContentResolver, com a permissão temporária
 * que o app de origem concede, e vai ao Dart como nome + bytes: nada é
 * copiado para o armazenamento. Quem decide se é extrato é o conteúdo, na
 * prévia da importação.
 */
class MainActivity : FlutterActivity() {
    private var canal: MethodChannel? = null

    /** O arquivo que chegou antes de o Dart pedir (abertura a frio). */
    private var pendente: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL).also {
            it.setMethodCallHandler { chamada, resposta ->
                if (chamada.method == "pegarPendente") {
                    resposta.success(pendente)
                    pendente = null
                } else {
                    resposta.notImplemented()
                }
            }
        }
        pendente = lerArquivoRecebido(intent)
        // Lido uma vez: girar a tela ou voltar ao app não reentrega.
        intent = Intent(intent).apply {
            action = Intent.ACTION_MAIN
            data = null
            removeExtra(Intent.EXTRA_STREAM)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val arquivo = lerArquivoRecebido(intent) ?: return
        val c = canal
        if (c == null) {
            pendente = arquivo
        } else {
            c.invokeMethod("arquivoRecebido", arquivo)
        }
    }

    private fun lerArquivoRecebido(intent: Intent?): Map<String, Any>? {
        if (intent == null) return null
        val uri: Uri = when (intent.action) {
            Intent.ACTION_SEND -> uriCompartilhado(intent)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        } ?: return null
        val nome = nomeDe(uri)
        return try {
            val bytes = contentResolver.openInputStream(uri)?.use { entrada ->
                entrada.readBytes()
            } ?: return mapOf("erro" to "ilegivel", "nome" to nome)
            if (bytes.size > LIMITE_BYTES) {
                mapOf("erro" to "grande", "nome" to nome)
            } else {
                mapOf("nome" to nome, "bytes" to bytes)
            }
        } catch (e: Exception) {
            mapOf("erro" to "ilegivel", "nome" to nome)
        }
    }

    @Suppress("DEPRECATION")
    private fun uriCompartilhado(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun nomeDe(uri: Uri): String {
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val nome = cursor.getString(0)
                        if (!nome.isNullOrBlank()) return nome
                    }
                }
        } catch (_: Exception) {
            // Provedor sem nome de exibição: cai no último segmento.
        }
        return uri.lastPathSegment?.substringAfterLast('/') ?: "arquivo"
    }

    companion object {
        private const val CANAL = "desmalha/arquivo_recebido"

        /** Extrato de um ano de conta pessoal cabe com folga; acima disso,
         *  não é extrato, e ler inteiro na memória seria o problema. */
        private const val LIMITE_BYTES = 20 * 1024 * 1024
    }
}
