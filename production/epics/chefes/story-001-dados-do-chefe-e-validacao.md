# Story 001: Dados do chefe (EnemyDef, BossPatternDef, ChefesTuning) e validação CH1–CH8

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (Formulas › Tabela consolidada: `ChefesTuning`, ficha do `soberano_do_limiar`, Validação CH1–CH8; F5)
**Requirement**: `TR-chefes-001`, `TR-chefes-006` (campo `raio_secundario_px` e CH8)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0014: Telégrafos (CH8 / `raio_secundario_px`)
**ADR Decision Summary**: chefe = `EnemyDef` com `comportamento = chefe`, lista de 4 `BossPatternDef` e `ChefesTuning` único, validados na carga; erro bloqueia a carga, aviso vai ao relator. Valores convertidos para passos e px na carga (ADR-0018).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: MEDIUM
**Engine Notes**: `Resource` imutável; `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` para cópia.

**Control Manifest Rules (this layer)**:
- Required: esquema com limites e regras entre campos (ADR-0004)
- Forbidden: dimensões de telégrafo lidas de campos gravados (vêm de `FormasDeTelegrafo.derivar()`, ADR-0014)

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-22** Chefe com 3 padrões; padrão com `preparo_s = 0`; `lacaios_por_convergencia = 4 > max_lacaios_vivos = 3`: a carga falha com CH1, CH2 e CH3.
- [x] **AC-CH-21** Com as 3 armas (80, 90, 100 HP) e dano máx. 18, a validação cruzada CH5 dá ≥ 5 golpes e `t_min_morrer_s ≥ 2,67 s`, 0 avisos CH5.
- [x] **AC-CH-26** `EnemyDef` de fábrica: Padrão 3 com `raio_secundario_px = 420`, Padrões 0–2 com 0, zero CH8; com 200 no Padrão 3 (≤ 225) sai CH8; o puxão continua em 420 px mesmo com o campo mudado.

---

## Implementation Notes

*Derived from ADR-0004 / ADR-0018 Implementation Guidelines:*

- `assets/data/tuning/chefes_tuning.tres` e a ficha `soberano_do_limiar` pela tabela do GDD.
- Nenhum número de jogo literal no código do chefe; conversão s→passos na carga.

---

## Out of Scope

- Story 002+: comportamento.

---

## Files

- `assets/data/tuning/chefes_tuning.tres`, `assets/data/inimigos/soberano_do_limiar.tres`
- `src/gameplay/chefes/boss_pattern_def.gd`, `src/gameplay/chefes/chefes_tuning.gd`, `src/gameplay/chefes/validacao_chefes.gd`
- `tests/integration/chefes/chefes_validacao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/chefes/chefes_validacao_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épicos `production/epics/conteudo/EPIC.md` (validador), `production/epics/armas-das-doutrinas/EPIC.md` (Vida das armas para CH5), `production/epics/telegrafos/EPIC.md` (`FormasDeTelegrafo.derivar()`)
- Unlocks: `production/epics/chefes/story-002-maquina-de-fases-do-chefe.md`

**Código da fatia**: nenhum código de chefe; construção do zero.
