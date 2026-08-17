/**
 * Exclusão de conta — a ordem dos três passos, isolada do HTTP e da rede.
 *
 * O fluxo está definido em `supabase/README.md` e no comentário de
 * `20260815000352_exclusao_e_expurgo.sql`, e a ordem NÃO é arbitrária:
 *
 *   1. apagar os objetos do usuário nos buckets, pela Storage API;
 *   2. `conformidade.encerrar_conta(<uuid>)`;
 *   3. banir o usuário, o que também derruba as sessões abertas.
 *
 * O passo 1 vem primeiro porque não pode ser feito em SQL — o Supabase bloqueia
 * `DELETE` direto em `storage.objects` (`storage.protect_delete`), e apagar a
 * linha não removeria o arquivo no backend de objetos: sobraria o blob vivo com
 * o registro limpo, a pior combinação possível. O passo 2 CONFERE que não
 * sobrou nenhum objeto no prefixo do usuário e recusa encerrar enquanto sobrar.
 * Ou seja: o banco é a testemunha de que a Storage API foi mesmo chamada.
 *
 * Daí a regra que este módulo existe para garantir: **um passo que falha
 * interrompe os seguintes**. Banir um usuário cujo blob continua no bucket
 * produziria exatamente o resultado que a PP v0.2 promete não produzir — conta
 * inacessível, dado retido. Mesma postura da guia de DARF que sai sem código de
 * barras: falhar visível em vez de registrar como feito o que não foi feito.
 */

/** Buckets onde um usuário pode ter arquivo. Espelha `encerrar_conta`. */
export const BALDES_DO_USUARIO = ["backups", "suporte-extratos"] as const;

/**
 * Duração do banimento aplicado no passo 3.
 *
 * Não precisa ser exata: o banimento só tem de sobreviver aos 30 dias de
 * carência, porque depois disso `expurgar_contas_encerradas` apaga a linha de
 * `auth.users` e não há mais o que banir. Um valor longo diz "até a linha
 * sumir" sem depender de acertar o relógio da rotina de expurgo.
 */
export const DURACAO_BANIMENTO = "876000h";

/** Uma entrada devolvida pela listagem de um prefixo. */
export interface EntradaArmazenada {
  /** Nome relativo ao prefixo consultado, sem barras. */
  nome: string;
  /** Pastas não são objetos: entram para serem percorridas, não apagadas. */
  ehPasta: boolean;
}

/** O mínimo da Storage API de que este fluxo depende. */
export interface ApiDeArmazenamento {
  /** Uma página das entradas DIRETAS de `prefixo` (sem descer nas pastas). */
  listarPagina(
    balde: string,
    prefixo: string,
    deslocamento: number,
    limite: number,
  ): Promise<EntradaArmazenada[]>;

  /** Remove os objetos de `caminhos` (caminhos completos dentro do balde). */
  remover(balde: string, caminhos: string[]): Promise<void>;
}

/** O que a edge function precisa do banco, com `service_role`. */
export interface RegistroDeConformidade {
  /** Executa `conformidade.encerrar_conta(usuarioId)`. */
  encerrarConta(usuarioId: string): Promise<void>;
}

/** O que a edge function precisa da Auth Admin API. */
export interface AdministracaoDeIdentidade {
  /**
   * Bane o usuário por [duracao], fechando a porta de entrada.
   *
   * ⚠️ O banimento impede entrar de novo e renovar a sessão, mas **não invalida
   * um access token que já foi emitido** — ele é conferido por assinatura, sem
   * ida ao servidor, e vale até expirar (uma hora, no padrão do Supabase).
   * Ou seja: a janela entre a exclusão e a expiração do último token existe, e
   * não adianta fingir que não. O que ela permite é pouco, porque a essa altura
   * os arquivos já foram apagados e o perfil já está marcado como excluído —
   * mas está escrito aqui para que ninguém prometa "sessão derrubada na hora".
   */
  banir(usuarioId: string, duracao: string): Promise<void>;
}

export interface Dependencias {
  armazenamento: ApiDeArmazenamento;
  conformidade: RegistroDeConformidade;
  identidade: AdministracaoDeIdentidade;
}

/** Em que passo a exclusão parou, quando parou. */
export type PassoDaExclusao = "arquivos" | "encerramento" | "banimento";

export class FalhaNaExclusao extends Error {
  constructor(
    readonly passo: PassoDaExclusao,
    mensagem: string,
    readonly causa?: unknown,
  ) {
    super(mensagem);
    this.name = "FalhaNaExclusao";
  }
}

export interface RelatorioDeExclusao {
  usuarioId: string;
  /** Quantos objetos foram removidos, por balde. Vai para o log, não para a tela. */
  arquivosRemovidos: Record<string, number>;
}

/**
 * Página de listagem. O padrão da Storage API é 100; pedir mais não muda a
 * corretude porque a varredura pagina de qualquer jeito.
 */
const TAMANHO_DA_PAGINA = 100;

/**
 * Quantos caminhos por chamada de remoção.
 *
 * Uma pasta com muitos backups não pode virar uma requisição gigante que o
 * gateway corta no meio — e um corte no meio deixaria objeto para trás, que o
 * passo 2 recusaria. Melhor fatiar aqui.
 */
const TAMANHO_DO_LOTE = 100;

/**
 * Profundidade máxima ao descer nas pastas do usuário.
 *
 * A convenção de caminho é `<uid>/<arquivo>` — um nível. O limite existe porque
 * a listagem é dado vindo de fora: um ciclo ou um aninhamento absurdo não pode
 * virar recursão infinita dentro de uma função com tempo de execução contado.
 * Estourar o limite é falha, não truncamento silencioso: um objeto esquecido
 * fica retido, e é justamente o que este fluxo existe para evitar.
 */
const PROFUNDIDADE_MAXIMA = 8;

/**
 * Executa a exclusão de conta de `usuarioId`, na ordem obrigatória.
 *
 * Lança [FalhaNaExclusao] no primeiro passo que falhar, sem executar os
 * seguintes.
 */
export async function excluirConta(
  deps: Dependencias,
  usuarioId: string,
): Promise<RelatorioDeExclusao> {
  if (!ehUuid(usuarioId)) {
    throw new FalhaNaExclusao(
      "arquivos",
      `identificador de usuário inválido: ${usuarioId}`,
    );
  }

  const arquivosRemovidos: Record<string, number> = {};
  for (const balde of BALDES_DO_USUARIO) {
    try {
      arquivosRemovidos[balde] = await esvaziarPasta(
        deps.armazenamento,
        balde,
        usuarioId,
      );
    } catch (erro) {
      throw new FalhaNaExclusao(
        "arquivos",
        `não foi possível apagar os arquivos do usuário em "${balde}"`,
        erro,
      );
    }
  }

  try {
    await deps.conformidade.encerrarConta(usuarioId);
  } catch (erro) {
    // Inclui o caso em que o banco recusou por ainda haver objeto no bucket:
    // sinal de que a varredura acima não pegou tudo. Continuar daqui seria
    // banir o usuário e deixar o arquivo dele para trás.
    throw new FalhaNaExclusao(
      "encerramento",
      "o banco recusou encerrar a conta",
      erro,
    );
  }

  try {
    await deps.identidade.banir(usuarioId, DURACAO_BANIMENTO);
  } catch (erro) {
    throw new FalhaNaExclusao(
      "banimento",
      "a conta foi encerrada, mas as sessões não puderam ser derrubadas",
      erro,
    );
  }

  return { usuarioId, arquivosRemovidos };
}

/**
 * Apaga tudo o que existir sob `<prefixo>/` no balde, e devolve quantos foram.
 *
 * Percorre as pastas porque a listagem da Storage API é de um nível só. A
 * convenção do projeto é `<uid>/<arquivo>`, mas um objeto gravado um nível
 * abaixo continuaria contando em `encerrar_conta` — que conta por
 * `(storage.foldername(name))[1]`, a QUALQUER profundidade. Varrer só o
 * primeiro nível deixaria a conta impossível de encerrar.
 */
async function esvaziarPasta(
  api: ApiDeArmazenamento,
  balde: string,
  prefixo: string,
  profundidade = 0,
): Promise<number> {
  if (profundidade >= PROFUNDIDADE_MAXIMA) {
    throw new Error(
      `"${balde}/${prefixo}" passa de ${PROFUNDIDADE_MAXIMA} níveis de pasta`,
    );
  }

  const objetos: string[] = [];
  const pastas: string[] = [];

  for (let deslocamento = 0; ; deslocamento += TAMANHO_DA_PAGINA) {
    const pagina = await api.listarPagina(
      balde,
      prefixo,
      deslocamento,
      TAMANHO_DA_PAGINA,
    );
    for (const entrada of pagina) {
      const caminho = `${prefixo}/${entrada.nome}`;
      (entrada.ehPasta ? pastas : objetos).push(caminho);
    }
    if (pagina.length < TAMANHO_DA_PAGINA) break;
  }

  let removidos = 0;
  for (let i = 0; i < objetos.length; i += TAMANHO_DO_LOTE) {
    const lote = objetos.slice(i, i + TAMANHO_DO_LOTE);
    await api.remover(balde, lote);
    removidos += lote.length;
  }

  for (const pasta of pastas) {
    removidos += await esvaziarPasta(api, balde, pasta, profundidade + 1);
  }

  return removidos;
}

const FORMATO_UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * O identificador vira prefixo de caminho na Storage API e argumento de SQL.
 *
 * Conferir o formato aqui é o que impede que um valor inesperado — vindo de um
 * token adulterado, por exemplo — seja usado como prefixo e acabe listando (ou
 * apagando) a pasta de outra pessoa.
 */
export function ehUuid(valor: string): boolean {
  return FORMATO_UUID.test(valor);
}
