# Story 005: Spawn — 14 candidatos, filtros, ordem e distância da acuada

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R7, R7-P, F3, F3-P)
**Requirement**: `TR-camaras-006`, `TR-camaras-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico (Emenda Pactos); ADR-0018: IA de inimigos e chefe
**ADR Decision Summary**: O fluxo 3 `spawn` sorteia sempre 14 candidatos (28 reais) por nascimento antes de escolher; os filtros (jogador, pedras, `spawn_dist_acuada_px`) agem sobre a lista já sorteada e só mudam qual candidato vence; sem nenhum válido, vale o último; `ordem` é dado das Câmaras para a IA e não toca RNG.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Nenhuma API de engine.

**Control Manifest Rules (Feature)**:
- Forbidden: RNG da engine; consumo de `spawn` variável

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-09: 14 candidatos, 28 reais, sempre; candidato a 390,0 px do jogador recusado, a 390,1 px escolhido; sem válido vale o 14º.
- [x] AC-CO-10 (parte pedras): candidato a r_pedra + raio + 12 recusado; + 12,1 aceito.
- [x] AC-CO-37 / AC-CO-38: a IA recebe `ordem` 0, 1, 2 na ordem da composição (dentro e fora do encontro); acuada em (960; 540) recusa (1100; 480) e aceita (1200; 400); 240,0 px recusado, 240,1 aceito; acuada em `Fugiu` não filtra.
- [x] AC-CO-11 (parte `spawn`): posição do jogador não muda o estado do fluxo `spawn` depois da câmara.

---

## Implementation Notes

- Inimigos nascem como `InimigoRef` na lista estável da IA (ADR-0003/ADR-0018).

---

## Out of Scope

- Story 006: nascimento da acuada (pontos fixos, Vínculo)

---

## Files

- `src/gameplay/camaras/spawn.gd`
- `tests/unit/camaras/spawn_e_candidatos_test.gd`

Código atual da fatia: posições fixas de `game_session.gd::_spawn_wave` são **substituídas**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/spawn_e_candidatos_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-003-layout-de-pedras.md`, `production/epics/camaras-e-ondas/story-004-composicao-das-ondas.md`
- Unlocks: `production/epics/camaras-e-ondas/story-006-montagem-na-transicao.md`
