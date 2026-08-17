/**
 * A página pública de exclusão de conta.
 *
 * Existe porque o Google Play exige, de quem deixa criar conta no app, um
 * endereço **web** onde a exclusão possa ser pedida sem instalar nada — quem
 * trocou de celular ou já desinstalou o app precisa conseguir chegar aqui.
 *
 * A política da loja também exige dizer, na própria página, **o que é apagado,
 * o que é retido e por quanto tempo**. Isso não é texto de enfeite: são os três
 * prazos da PP v0.2, que no backend são executados por rotina
 * (`20260815000352_exclusao_e_expurgo.sql`). O teste desta página confere que os
 * três continuam escritos aqui — se um prazo mudar no banco e não mudar no
 * texto, a página passa a mentir para o usuário e para a loja.
 *
 * Tudo embutido, sem recurso externo: a página tem de abrir num aparelho velho,
 * numa rede ruim, sem CDN e sem fonte remota.
 *
 * 🔴 ESTA PÁGINA NÃO RENDERIZA SERVIDA DE `*.supabase.co`. Medido em
 * 17/ago/2026: o gateway reescreve o `text/html` desta resposta para
 * `text/plain` e injeta `Content-Security-Policy: default-src 'none'; sandbox`.
 * Com o `nosniff` junto, quem abre o link vê o código-fonte; e mesmo que
 * renderizasse, a CSP mataria o script do formulário. É consistente com uma
 * proteção anti-phishing do domínio deles, e vale só para HTML — as rotas de
 * `POST` continuam devolvendo JSON normalmente.
 *
 * O HTML aqui continua correto e continua sendo a fonte da página; o que muda é
 * de onde ele é servido. Ver `supabase/operacao/publicacao.md`, seção "O
 * endereço que vai para o Google Play".
 */

/** Prazos da PP v0.2, seção 9. A página e o banco têm de contar a mesma coisa. */
export const PRAZOS = {
  arquivos: "imediatamente, sem carência",
  conta: "30 dias",
  aceite: "5 anos",
} as const;

export function paginaExclusao(): string {
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Excluir minha conta — Desmalha</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 24px 16px 64px;
    font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    background: Canvas; color: CanvasText;
  }
  main { max-width: 34rem; margin: 0 auto; }
  h1 { font-size: 1.5rem; line-height: 1.3; margin: 0 0 8px; }
  h2 { font-size: 1rem; margin: 32px 0 8px; }
  p, li { margin: 0 0 12px; }
  ul { padding-left: 1.25rem; }
  label { display: block; font-weight: 600; margin-bottom: 6px; }
  input[type=email], input[type=text] {
    width: 100%; padding: 12px; font: inherit; border-radius: 8px;
    border: 1px solid GrayText; background: Field; color: FieldText;
  }
  input[type=text] { letter-spacing: 0.3em; font-variant-numeric: tabular-nums; }
  button {
    width: 100%; margin-top: 16px; padding: 14px; font: inherit; font-weight: 600;
    border: 0; border-radius: 8px; background: #b3261e; color: #fff; cursor: pointer;
  }
  button[disabled] { opacity: .5; cursor: progress; }
  .aviso {
    border-left: 4px solid #b3261e; padding: 4px 0 4px 14px; margin: 24px 0;
  }
  .recado { margin-top: 20px; padding: 14px; border-radius: 8px; background: #8883; }
  .recado.erro { border: 1px solid #b3261e; }
  .escondido { display: none; }
  footer { margin-top: 48px; font-size: .875rem; color: GrayText; }
</style>
</head>
<body>
<main>
  <h1>Excluir minha conta do Desmalha</h1>
  <p>
    Você pode pedir a exclusão aqui mesmo, sem precisar do aplicativo instalado.
    Para confirmar que a conta é sua, enviamos um código para o e-mail dela.
  </p>

  <div class="aviso">
    <strong>Esta ação não tem volta.</strong>
    Seus backups são apagados na hora e não há como recuperá-los depois — nem
    por nós: eles são cifrados com uma chave que só você tem.
  </div>

  <form id="forma" novalidate>
    <div id="etapa-email">
      <label for="email">E-mail da conta</label>
      <input id="email" name="email" type="email" autocomplete="email"
             autocapitalize="none" spellcheck="false" required>
      <button id="botao-codigo" type="submit">Enviar código</button>
    </div>

    <div id="etapa-codigo" class="escondido">
      <label for="codigo">Código recebido por e-mail</label>
      <input id="codigo" name="codigo" type="text" inputmode="numeric"
             autocomplete="one-time-code" maxlength="8" required>
      <button id="botao-excluir" type="button">Excluir minha conta</button>
    </div>
  </form>

  <div id="recado" class="recado escondido" role="status" aria-live="polite"></div>

  <h2>O que acontece com cada coisa</h2>
  <ul>
    <li>
      <strong>Seus backups e qualquer arquivo enviado ao suporte:</strong>
      apagados <strong>${PRAZOS.arquivos}</strong>.
    </li>
    <li>
      <strong>Sua conta e seu cadastro:</strong> a conta é bloqueada na hora e
      apagada em definitivo depois de <strong>${PRAZOS.conta}</strong>.
    </li>
    <li>
      <strong>O registro de que você aceitou os termos:</strong> mantido por
      <strong>${PRAZOS.aceite}</strong>, desvinculado do seu cadastro. Ele deixa
      de apontar para você e passa a existir só como prova de que o aceite
      ocorreu, o que a lei nos permite guardar para exercer direitos.
    </li>
  </ul>

  <h2>O que fica no seu celular</h2>
  <p>
    Seus lançamentos, o livro-caixa e as apurações <strong>nunca estiveram
    no nosso servidor</strong> — eles vivem cifrados dentro do aplicativo, no seu
    aparelho. Excluir a conta aqui não apaga esses dados do celular. Para
    eliminá-los, desinstale o aplicativo.
  </p>
  <p>
    Se você ainda precisa deles, exporte antes: a lei exige que você guarde os
    comprovantes por cinco anos, e nós não teremos como devolvê-los.
  </p>

  <footer>Desmalha — controle de carnê-leão.</footer>
</main>

<script>
(function () {
  var forma = document.getElementById('forma');
  var email = document.getElementById('email');
  var codigo = document.getElementById('codigo');
  var etapaEmail = document.getElementById('etapa-email');
  var etapaCodigo = document.getElementById('etapa-codigo');
  var botaoCodigo = document.getElementById('botao-codigo');
  var botaoExcluir = document.getElementById('botao-excluir');
  var recado = document.getElementById('recado');

  function mostrar(texto, ehErro) {
    // textContent, nunca innerHTML: a mensagem passa por dados de fora.
    recado.textContent = texto;
    recado.className = 'recado' + (ehErro ? ' erro' : '');
  }

  function pedir(corpo) {
    return fetch(location.pathname, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(corpo)
    }).then(function (r) {
      return r.json().catch(function () { return {}; }).then(function (d) {
        return { ok: r.ok, dados: d };
      });
    });
  }

  function ocupado(botao, sim) {
    botao.disabled = sim;
  }

  forma.addEventListener('submit', function (evento) {
    evento.preventDefault();
    if (!email.value.trim()) return;
    ocupado(botaoCodigo, true);
    pedir({ acao: 'enviar-codigo', email: email.value })
      .then(function (r) {
        // Resposta deliberadamente igual exista ou não a conta: esta página é
        // pública, e dizer "esse e-mail não tem conta" a transformaria num
        // consultor de quem é cliente do Desmalha.
        mostrar(r.dados.mensagem || 'Se houver uma conta com esse e-mail, o código foi enviado.', !r.ok);
        etapaEmail.classList.add('escondido');
        etapaCodigo.classList.remove('escondido');
        codigo.focus();
      })
      .catch(function () { mostrar('Não foi possível falar com o servidor. Tente de novo.', true); })
      .then(function () { ocupado(botaoCodigo, false); });
  });

  botaoExcluir.addEventListener('click', function () {
    if (!codigo.value.trim()) return;
    if (!confirm('Confirma excluir a conta? Os backups são apagados agora e não há como recuperá-los.')) return;
    ocupado(botaoExcluir, true);
    pedir({ acao: 'confirmar', email: email.value, codigo: codigo.value })
      .then(function (r) {
        if (r.ok) {
          etapaCodigo.classList.add('escondido');
          mostrar('Conta excluída. Seus backups foram apagados e a conta será removida em definitivo em ${PRAZOS.conta}.', false);
        } else {
          mostrar(r.dados.mensagem || 'Não foi possível concluir. Tente de novo.', true);
        }
      })
      .catch(function () { mostrar('Não foi possível falar com o servidor. Tente de novo.', true); })
      .then(function () { ocupado(botaoExcluir, false); });
  });
})();
</script>
</body>
</html>
`;
}
