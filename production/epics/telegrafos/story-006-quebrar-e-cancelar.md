# Story 006: Quebrar, cancelar, troca de câmara e TransicaoFase

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R7, R7a, Edge Cases)
**Requirement**: `TR-telegrafos-008`, `TR-telegrafos-017`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisões 3, 7); ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `quebrar(id)` só em `CRESCENDO` (item 5 vence o disparo do mesmo passo); elite e chefe não chamam. `varrer()` cancela `CRESCENDO` com dono morto; `cancelar(id)` na `TransicaoFase` e na queda do chefe. `cancelar_todos()` na ação 3 da Transição, antes de as Câmaras removerem inimigos, sem evento, com `PoliticaDeTroca` injetada — **`LIBERAR_JA`** é a política do jogo (decisão do usuário 2026-11-15).
**ADR Version**: ADR-0014 2026-11-16 · ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (regra); HIGH herdado do ADR-0001 para o quadro da Transição

**Control Manifest Rules (this layer)**:
- Required: `cancelar_todos()` antes de as Câmaras removerem inimigos, sem evento
- Forbidden: módulo de regra emitir fora de passo vivo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TG-15 — golpe pesado com empurrão > 0 no passo 20: `quebrado` (2 passos), sem `ferir_jogador`, recuperação 24; empurrão 0, elite e chefe: não quebram
- [x] AC-TG-16 — dono Vida ≤ 0: `cancelado` 2 passos, sem dano/projétil; câmara nova: zero telégrafos ativos logo após o corte
- [x] AC-TG-38 — chefe cai a 335 HP no passo 20 do Padrão 2: `cancelado` no mesmo passo, sem dano/projéteis/flash; chefe a Vida ≤ 0 com 2 lacaios em preparo: 3 `cancelado` no mesmo passo

---

## Implementation Notes

- `passo_de_transicao()` existe só para `FADE_DOIS_PASSOS`; com `LIBERAR_JA` é no-op.
- Evento `TelegrafoCancelado(dono_id, causa)` só em passo vivo; a quebra segue o `quebrou` do Combate.

---

## Out of Scope

- Pedido de recuperação à IA (épico IA story-005)

---

## Files

- src/gameplay/telegrafos/telegrafos.gd
- tests/unit/telegrafos/telegrafos_quebrar_e_cancelar_test.gd

Fatia: `game_session.gd` não tem quebra nem cancelamento na troca — nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_quebrar_e_cancelar_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-001-pool-teto-e-ciclo.md`; épico `production/epics/orquestrador-do-passo/` (seis ações da Transição)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-005-elites-armadura-e-quebra.md`, `production/epics/ia-de-inimigos-e-elites/story-009-chefe-ativo-e-lacaios.md`
