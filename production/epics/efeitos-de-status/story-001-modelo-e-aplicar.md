# Story 001: Modelo de status e aplicar_status

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R1, R2, R10, F1)
**Requirement**: `TR-status-001`, `TR-status-002`, `TR-status-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Entidades e portadores; ADR-0010: Resolução do combate no passo; ADR-0002: Canal de eventos; ADR-0009: Atributos e modificadores
**ADR Decision Summary**: Estado por inimigo em registro `RefCounted` (ADR-0003); `aplicar_status(alvo_id, id, n)` é chamada síncrona do Combate/Selo, exceção explícita ao "só para baixo" (ADR-0002, ADR-0010 §8); o módulo implementa a interface `ModuloDeStatus` definida pelo Combate.
**ADR Version**: ADR-0003 2026-11-16 · ADR-0010 2026-11-16 · ADR-0002 2026-11-16 · ADR-0009 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (só `RefCounted`, `Array` tipado, `float`)
**Engine Notes**: ADR-0003 sem API pós-cutoff; regra 4.7: `override` com retorno não-void exige `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: dependências no `_init`/`configurar`, criação via composição (ADR-0015); lógica pura
- Forbidden: Autoload, `get_node` absoluto em lógica, `SceneTree.paused`
- Guardrail: sem alocação por passo (estado pré-alocado por inimigo)

---

## Acceptance Criteria

*From GDD `design/gdd/efeitos-de-status.md`, scoped to this story:*

- [x] AC-ST-01 — Sangramento n=1: A=1, `restante` 240; −0,04 por passo; Vida 990,4 (±1e-6) depois do passo 239
- [x] AC-ST-02 — reaplicar no passo 100: A=2, `restante` 240; Vida final 976,8
- [x] AC-ST-03 — teto 10 do Sangramento; com `max_acumulos_sangramento` 0, A=12
- [x] AC-ST-04 — Queimadura n=1 (Vida 985,6) e teto 6 (Vida 913,6)
- [x] AC-ST-05 — n fracionário 0,5 (Vida 995,2)
- [x] AC-ST-07 — n ≤ 0, alvo surgindo ou Vida ≤ 0: nada muda
- [x] AC-ST-26 (parte R10) — `StatusTuning`, lista de inimigos e `ferir_inimigo` vêm de dublês, sem SceneTree

---

## Implementation Notes

- `ModuloDeStatus extends RefCounted` com `aplicar_status(alvo_id, id, n)`, `tick(inimigo_id)`, `limpar_todos()` (assinaturas do ADR-0010 §"Key Interfaces"; o Combate é dono da interface).
- Registro por inimigo: Sangramento e Queimadura com acúmulos `float` + `restante: int`; Abalo com `restante: int`. Reaplicar segue F1 (acúmulos somam até o teto, `restante` volta ao cheio).
- Recusar alvo não atingível consultando a IA (`atingivel`/`vivo`), sem guardar `InimigoRef`.
- Durações já convertidas em passos na carga (ADR-0004); nenhum literal de jogo.
- O dano em si (tick) é a story 002; aqui só estado e aplicação. Os testes de Vida usam o `tick` da 002 — escrever os testes de AC-ST-01..05 junto com a 002 se a ordem exigir.

---

## Out of Scope

- story-002: dano por passo no item 7
- story-004: Abalo e fonte no portador
- story-007: validação do `StatusTuning`

---

## Files

- src/gameplay/status/modulo_de_status.gd
- src/gameplay/status/estado_de_status.gd
- tests/unit/status/status_aplicar_test.gd

Código atual da fatia: nenhum código de status existe (`game_session.gd` não tem status) — construção do zero.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status/status_aplicar_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: épico `production/epics/combate-nucleo/` (interface `ModuloDeStatus` e `ferir_inimigo_de_status`); épico `production/epics/conteudo/` (`StatusTuning` no catálogo)
- Unlocks: `production/epics/efeitos-de-status/story-002-tick-e-dano-silencioso.md`, `story-004-abalo.md`, `story-005-fontes-e-maldicoes.md`, `story-006-numero-e-consulta.md`
