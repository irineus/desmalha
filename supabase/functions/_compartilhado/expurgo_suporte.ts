/**
 * Expurgo dos 30 dias de `envios_suporte` — a ordem, isolada do HTTP.
 *
 * O envio ao suporte é a exceção única ao claim de privacidade, consentida
 * por 30 dias (PP v0.2). Passado o prazo, o arquivo tem de sair do bucket.
 * Apagar a linha em `storage.objects` não serve (o Supabase proíbe, e mesmo
 * que deixasse sobraria o arquivo vivo no backend de objetos): quem apaga é
 * a Storage API.
 *
 * E quem diz que apagou é o BANCO. `confirmar_expurgo_envios_suporte` só
 * carimba `excluido_em` quando a linha do objeto sumiu — resposta 2xx da
 * Storage API diz que o pedido foi aceito, não que o arquivo sumiu. Daí o
 * último passo: reler a lista de vencidos DEPOIS da confirmação. Sobrou
 * alguém, a execução FALHA, visível no log e no status HTTP — mesma postura
 * de `encerrar_conta` e da guia de DARF sem código de barras.
 */

/** O bucket de onde o expurgo apaga. Espelha a migration. */
export const BALDE_SUPORTE = "suporte-extratos";

/**
 * Quantos caminhos por chamada de remoção. A Storage API aceita lista, mas
 * não documenta teto; lotes pequenos deixam uma falha no meio com raio curto.
 */
export const TAMANHO_DO_LOTE = 100;

/** Um envio com a retenção vencida e sem exclusão confirmada. */
export interface EnvioVencido {
  id: string;
  path: string;
}

/** O que o expurgo precisa do mundo, com `service_role`. */
export interface DependenciasDoExpurgo {
  /** `public.envios_suporte_vencidos()`. */
  listarVencidos(): Promise<EnvioVencido[]>;
  /** Storage API: remove os caminhos do balde. */
  remover(balde: string, caminhos: string[]): Promise<void>;
  /** `public.confirmar_expurgo_envios_suporte()` — quantos carimbou. */
  confirmar(): Promise<number>;
}

/** O que a execução fez, sem nenhum caminho de arquivo (log não é inventário). */
export interface ResultadoDoExpurgo {
  vencidos: number;
  confirmados: number;
}

/** Sobrou envio vencido sem exclusão provada. */
export class ExpurgoIncompleto extends Error {
  constructor(readonly pendentes: number, readonly resultado: ResultadoDoExpurgo) {
    super(
      `${pendentes} envio(s) ao suporte seguem no bucket depois do prazo de ` +
        `30 dias: a Storage API aceitou o pedido, mas o banco não confirma ` +
        `que os arquivos sumiram`,
    );
    this.name = "ExpurgoIncompleto";
  }
}

export async function expurgarEnviosSuporte(
  dep: DependenciasDoExpurgo,
): Promise<ResultadoDoExpurgo> {
  const vencidos = await dep.listarVencidos();

  for (let i = 0; i < vencidos.length; i += TAMANHO_DO_LOTE) {
    const lote = vencidos.slice(i, i + TAMANHO_DO_LOTE).map((v) => v.path);
    // Falha de remoção sobe na hora: sem ela, a confirmação abaixo rodaria
    // e o resultado pareceria parcial-mas-ok. A próxima execução retoma.
    await dep.remover(BALDE_SUPORTE, lote);
  }

  // Roda mesmo sem vencidos: um arquivo apagado por fora (suporte, exclusão
  // de conta) também precisa do carimbo, e confirmar é idempotente.
  const confirmados = await dep.confirmar();
  const resultado = { vencidos: vencidos.length, confirmados };

  const pendentes = (await dep.listarVencidos()).length;
  if (pendentes > 0) throw new ExpurgoIncompleto(pendentes, resultado);

  return resultado;
}
