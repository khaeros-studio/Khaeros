# Story 005: Relógios t_vivo/t_apres, quadro() e troca de câmara em seis ações

> **Epic**: orquestrador-do-passo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/adr-0001-orquestrador-do-passo.md` (sem GDD)
**Requirement**: nenhum TR próprio. Sustenta TR-pipeline-004, TR-cena-009/011, TR-camaras-002/007.

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo
**ADR Decision Summary**: `quadro(delta_real)` avança `t_apres` com teto `dt_max_apres` (0,1 s) em JOGO/TRANSICAO/MORTE; em TRANSICAO com `progresso_wipe` ≥ 0,5 executa uma vez as seis ações da troca de câmara em ordem; `t_vivo`/`t_apres` zeram na troca, não no pedido.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `quadro()` pode ser chamado com 0, 1 ou vários `passo_fisico()` entre dois quadros. Valor de `dt_max_apres` depende de EX-0001-6.

**Control Manifest Rules (this layer)**:
- Required: seis ações da troca rodam uma única vez, no mesmo quadro, em ordem fixa; `t_vivo`/`t_apres` zeram na metade do wipe; `passos_em_jogo()` nunca zera na run; `dt_max_apres` vem de dados.
- Forbidden: assumir "um passo por quadro"; `Timer`/`create_timer`; ler `Time`/`OS` na lógica.
- Guardrail: relógios entregues ao Pipeline todo quadro (2 globais; custo medido em EX-0001-3).

---

## Acceptance Criteria

*Do ADR-0001 "Validation Criteria":*

- [ ] As seis ações da Transição rodam uma vez, em ordem, no primeiro quadro com `progresso_wipe` ≥ 0,5, e não rodam de novo nos quadros seguintes.
- [ ] `t_apres` avança `min(delta_real, dt_max_apres)` em JOGO, TRANSICAO e MORTE e fica parado em PAUSA e BENCAO; um `delta_real` de 1,0 s avança 0,1 s.
- [ ] `t_vivo` e `n_vivos` zeram na troca de câmara (não no pedido de `TRANSICAO`); `passos_em_jogo()` permanece.
- [ ] `quadro()` com 0 passos físicos desde o último quadro e com 3 passos acumulados não altera o número de passos executados.
- [ ] Os relógios são entregues ao Pipeline (interface injetada) a cada `quadro()`.
- [ ] Fim do wipe pede `JOGO` ao orquestrador (pedido, não escrita direta).

---

## Implementation Notes

As seis ações são injetadas como lista de `AcaoDeTroca` (ordem do Combate R1/Transição, definidas pelos donos; aqui falsos que registram a ordem). `dt_max_apres` e `TICK` vêm de constante única/`Resource` de dados.

---

## Out of Scope

- Conteúdo das seis ações (Câmaras, Cena, Combate); wipe visual (épico `pipeline-visual`).

---

## Files

- `src/foundation/orquestrador/orquestrador_do_passo.gd` (relógios, `quadro()`), `acao_de_troca.gd`
- `tests/unit/orquestrador/relogios_e_quadro_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/orquestrador/relogios_e_quadro_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/story-004-ordem-do-passo.md`, `production/epics/experimentos-de-engine/story-001-passo-e-quadro.md`
- Unlocks: `story-006-main-composicao.md`

---

## Completion Notes

**Concluída em**: 2026-11-16.

**Arquivos**: `src/foundation/orquestrador/acao_de_troca.gd` (`@abstract AcaoDeTroca.executar()`), `pipeline_de_relogios.gd` (interface nova: `receber_relogios(t_vivo, t_apres)` e `progresso_wipe()`), `quadro()`/`configurar_quadro()` em `orquestrador_do_passo.gd`; teste `tests/unit/orquestrador/relogios_e_quadro_test.gd`.

**Testes**: 8 casos, 8 passaram (seis ações uma vez e em ordem no 1º quadro com wipe ≥ 0,5; teto `dt_max_apres` em JOGO/TRANSICAO/MORTE, 1,0 s → 0,1 s; parado em PAUSA/BENCAO; zera na troca e não no pedido, `passos_em_jogo` permanece; 0 ou 3 passos entre quadros; relógios ao Pipeline todo quadro; fim do wipe pede JOGO; validação de seis ações).

**Decisões / desvios**:
- `dt_max_apres` é injetado em `configurar_quadro(pipeline, acoes, dt_max_apres)`; o `Main` passa o valor de dados (`VisualTuning`, Pipeline F8; esse Resource ainda não existe). O orquestrador não traz valor padrão literal.
- Ordem em `quadro()`: avança `t_apres`; em TRANSICAO consulta `progresso_wipe()`, faz a troca (zera `n_vivos`/`t_apres` e **depois** roda as seis ações) e, se progresso ≥ 1 com a troca feita, chama `pedir_estado(JOGO)`; por fim entrega os relógios. O progresso lido é o que o Pipeline tem no início do quadro.
- `PipelineDeRelogios` é um arquivo fora da lista da story: a story pede "interface injetada", sem nome.

**Pendências**: `VisualTuning.dt_max_apres` (épico pipeline-visual) e adaptadores reais das seis ações (story 006).
