# Story 007: Morte, abandono e regras da pausa

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R5, R5-P, R6, R4-P passo 4)
**Requirement**: `TR-run-005`, `TR-run-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§3); ADR-0001; ADR-0002; ADR-0012: UI e HUD; ADR-0006: Input por passo
**ADR Decision Summary**: morte vence a limpeza pela ordem do passo (`jogador_morreu` no item 9; `camara_limpa` no item 10 encontra a Run fora de `ATIVA`). Abandono permitido = `fase == ATIVA` e `PAUSA` vinda de `JOGO` e não `chefe_subjugado_pendente`; a UI pergunta `run.abandono_permitido()`. Pausa recusada em Transição, Morte e Encerrada.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: risco herdado do ADR-0001/0006/0012; a lógica da story é `RefCounted` pura.

**Control Manifest Rules (this layer)**:
- Required: `MORTE` vence qualquer outro pedido no mesmo passo (ADR-0001)
- Required: morte e abandono não tocam o saldo (ADR-0015 §6)
- Forbidden: flag extra para "morte vence" — vale a ordem do passo

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-12 / AC-RN-13 / AC-RN-16** `jogador_morreu` encerra com `morte` e o saldo não muda; com `recusou_morte`, segue Ativa; morte e `camara_limpa` no mesmo passo: encerra com `morte` e a limpeza é ignorada.
- [x] **AC-RN-35** `jogador_morreu` no mesmo passo do abate do chefe: `morte`, `desfecho_chefe = nenhum`, nenhuma vitória.
- [x] **AC-RN-14 / AC-RN-11** Confirmar abandono encerra com `abandono` e mantém o saldo; cancelar não muda nada; após vitória, morte ou abandono, nenhuma Transição é pedida e a tela final abre 1 vez.
- [x] **AC-RN-15 / AC-RN-34** Pausa recusada em Transição, Morte e Encerrada; abre em Jogo e Bênção; em Bênção e depois de `chefe_subjugado`, "Abandonar run" desabilitado e confirmar não encerra.

---

## Implementation Notes

*Derived from ADR-0015 §3:*

- `abandono_permitido() -> bool`; `SessaoDeJogo.abandonar()` fora do passo.
- Teste de "mesmo passo" com o orquestrador real e dublês de Combate/Câmaras emitindo nos itens 9 e 10.

---

## Out of Scope

- Story 009: o menu de pausa em si (UI).
- Story 010: `encerrar_por_saida()`.

---

## Files

- `src/gameplay/run/run.gd`
- `tests/unit/run/run_morte_abandono_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/run/run_morte_abandono_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-005-composicao-e-escopo-da-run.md`, `production/epics/run-e-regioes/story-008-resumo-da-run.md`; épico `production/epics/combate-nucleo/EPIC.md` (`jogador_morreu`, `recusou_morte`)
- Unlocks: `production/epics/run-e-regioes/story-009-telas-de-inicio-pausa-e-final.md`

**Código da fatia**: morte/menu da fatia em `game_session.gd`/`main.gd` — **substituir**.
