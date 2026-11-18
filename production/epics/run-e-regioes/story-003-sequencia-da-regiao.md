# Story 003: Sequência da região — proxima(i), avancar() e regiões reservadas

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R3, R3-P, R9, R10; F1)
**Requirement**: `TR-run-003`, `TR-run-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4); ADR-0004; ADR-0005: RNG determinístico
**ADR Decision Summary**: a Run é a fonte única da sequência: `proxima(i)` devolve o tipo de `i + 1` se `i + 1 < camaras_jogaveis`, senão `FIM_DA_RUN`; montar índice ≥ `camaras_jogaveis` é RN3. `p`/`p_max` são das Câmaras; a chave dos fluxos de estrutura é `(regiao, i)` vinda da Run; o índice da região entra na chave e no orçamento.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: nenhuma API de engine.

**Control Manifest Rules (this layer)**:
- Required: posse resolvida — `p_max` é das Câmaras (architecture.md, Conflitos de posse)
- Forbidden: a Run calcular `p`/`p_max`

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-06** No índice 2 a próxima é `santuario`; no índice 3, `combate`.
- [x] **AC-RN-30** Índice 4 → `combate`; índice 5 → `chefe`; índice 6 → `fim_da_run`; montar o índice 6 não dá erro; montar o 7 dá RN3. (AC-RN-07 vale com a `RegionDef` dublê de 6.)
- [x] **AC-RN-21** O Limiar dá `p_max` 4 (lido das Câmaras); com uma `RegionDef` dublê de 3 câmaras de combate jogáveis, 2.
- [x] **AC-RN-22** Com uma região, a próxima região é `fim_da_run`; com duas (dublê, 2 e 3 câmaras), a 2ª começa na câmara 0 e o índice da região entra no orçamento de onda.

---

## Implementation Notes

*Derived from ADR-0015 §4:*

- `proxima(i) -> StringName`, `avancar()` (`i += 1`, chamado pelas Portas), `chave_estrutura() -> Vector2i(regiao_idx, i)`.
- AC-RN-21 testa a leitura via dublê de Câmaras (a Run não calcula `p_max`).

---

## Out of Scope

- Épico `camaras-e-ondas`: montagem da câmara e cálculo de `p`.

---

## Files

- `src/gameplay/run/run.gd`
- `tests/unit/run/run_sequencia_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/run/run_sequencia_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-001-maquina-de-estados-da-run.md`, `production/epics/run-e-regioes/story-002-run-tuning-e-validacao.md`
- Unlocks: `production/epics/portas-e-recompensas/story-003-portas-forcadas-e-chaves.md`, `production/epics/portas-e-recompensas/story-007-escolha-da-porta.md`, `production/epics/run-e-regioes/story-004-inicio-da-run.md`

**Código da fatia**: a fatia tem uma câmara com três ondas, sem sequência; nada a reaproveitar.
