# Story 004: PoolDeNumeros — faixas por alvo, soma, teto 6 e número agregado jogador + Maldição

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Números de dano por alvo em três faixas (`golpe`, `dourado`, `status`), com soma em 300 ms, teto de 6 vivos, regra de saída e o dano da Maldição somando na faixa `golpe` do mesmo alvo.

**GDD**: `design/gdd/feedback-de-combate.md` (R6, R16, F1, F2)
**Requirement**: `TR-feedback-007`, `TR-feedback-015` (número agregado)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual (§8); ADR-0002: Canal de eventos
**ADR Decision Summary**: `PoolDeNumeros` (RefCounted, puro) na Apresentação, no relógio `t_apres`; golpe soma se `t_agora − t_nasceu ≤ janela_soma_s`; dourado nunca soma; soma em fração, arredonda no fim (< 0,5 sem número); cada soma reinicia a vida de 0,6 s; teto 6 sai pela F2; status chega pronto do módulo de Status e não soma com golpe.
**ADR Version**: ADR-0011 2026-11-16; ADR-0002 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura.

**Control Manifest Rules (this layer)**:
- Required: apresentação guiada por `t_apres`
- Forbidden: never string literal de interface (o texto do número é numérico; letreiros usam chave)
- Guardrail: VFX 64 draw calls

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-05 [L] F1 — soma por faixa
- [x] AC-FB-06 [L] F1 — dourado nunca soma
- [x] AC-FB-07 [L] F2 — teto (nunca mais de 6; ordem de remoção status → golpe → dourado)
- [x] AC-FB-08 [L] R6 — dano ao jogador não cria número
- [x] AC-FB-09 [L] R6/Edge — dano 0 e fração
- [x] AC-FB-34 [L] R16 — faixa golpe com Maldição ("10" → "20"; acerto marcado da Maldição nunca dourado)
- [x] AC-FB-35 [L] R16 — `maldicao_atingida` sem número; flash de Osso de 4 passos vivos
- [x] AC-FB-36 [L] R16 — técnica combinada: um número "26"

---

## Implementation Notes

*Derived from ADR-0011 §8:*

- A opção "Números de dano" (F5) desliga o pool sem mudar dano (story 006 testa as opções).
- `parede` e reflexo/explosão no mesmo alvo e passo somam ao golpe.

---

## Out of Scope

- `production/epics/efeitos-de-status/EPIC.md`: cálculo do valor do período de status

---

## Files

- `src/presentation/feedback/pool_de_numeros.gd`
- `tests/unit/feedback/pool_de_numeros_de_dano_test.gd`

Código da fatia: números desenhados em `world_view.gd::_effect`/`game_hud.gd` — **substituir**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/pool_de_numeros_de_dano_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/pool_de_numeros_de_dano_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/feedback-de-combate/story-002-arbitro-puro.md`
- Unlocks: `production/epics/feedback-de-combate/story-006-relogios-pausa-transicao-e-opcoes.md`, `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`
