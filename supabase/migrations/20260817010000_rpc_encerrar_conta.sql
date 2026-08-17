-- Desmalha — porta de entrada da edge function de exclusão de conta.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- POR QUE ESTA FUNÇÃO EXISTE
--
-- `conformidade.encerrar_conta` mora num schema privado, e schema privado é
-- invisível para o PostgREST: só os schemas expostos na configuração da API
-- podem ser chamados por RPC. A edge function de exclusão fala com o banco pela
-- API REST, como qualquer cliente — logo, não alcança `conformidade`.
--
-- As duas saídas seriam: expor o schema `conformidade` inteiro na API, ou abrir
-- uma porta estreita em `public`. Expor o schema entregaria de bandeja
-- `expurgar_contas_encerradas`, `expurgar_aceites_expirados` e a leitura da
-- chave de pseudonimização — todas rotinas que não têm por que ser alcançáveis
-- de fora. A porta estreita é o caminho que o comentário do schema
-- `conformidade` já previa em 15/ago: "tudo aqui roda por service_role ou por
-- função SECURITY DEFINER exposta em public".
--
-- SECURITY INVOKER, de propósito: quem chama precisa ter, ele mesmo, permissão
-- em `conformidade.encerrar_conta`. Só `service_role` tem. Se um dia um grant
-- for afrouxado por engano, esta função falha em vez de virar um contorno com
-- privilégio de dono — e um contorno silencioso para encerrar a conta dos
-- outros é exatamente o que não pode existir.

create or replace function public.encerrar_conta_do_usuario(p_usuario uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform conformidade.encerrar_conta(p_usuario);
end;
$$;

comment on function public.encerrar_conta_do_usuario(uuid) is
  'Passo 2 do fluxo de exclusão de conta, alcançável pelo PostgREST. Só '
  'service_role executa. A regra de recusar enquanto houver blob do usuário '
  'nos buckets é de conformidade.encerrar_conta e vale aqui igual.';

-- Em Postgres, função nova em `public` nasce executável por PUBLIC — e anon e
-- authenticated herdam disso. Sem este revoke, qualquer visitante da API
-- poderia encerrar a conta de qualquer uuid que adivinhasse.
revoke all on function public.encerrar_conta_do_usuario(uuid) from public;
revoke all on function public.encerrar_conta_do_usuario(uuid) from anon, authenticated;
grant execute on function public.encerrar_conta_do_usuario(uuid) to service_role;
