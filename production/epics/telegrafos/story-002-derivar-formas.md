# Story 002: FormasDeTelegrafo.derivar() dos EnemyDef e raio do alvo

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R5, F2, F3, F4, F7)
**Requirement**: `TR-telegrafos-005`, `TR-telegrafos-016`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisões 4, 10)
**ADR Decision Summary**: Dimensões derivadas do `EnemyDef` por `FormasDeTelegrafo.derivar(def, raio_alvo)`, a mesma função do validador TV2; nunca lidas de campos gravados no catálogo. Setor guarda `cos_meio` do catálogo; avanço com `R_c = raio_atacante + raio_alvo`, comprimento `percurso + 2 × R_c`, largura `2 × R_c`, `x_min = −R_c`. Maldição nunca cria telégrafo; teto não muda.
**ADR Version**: ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: precisão das fronteiras é NOT SOURCEABLE — vira teste (tolerâncias do GDD).

**Control Manifest Rules (this layer)**:
- Required: dimensões de `derivar()`
- Forbidden: dimensões lidas de campos gravados no catálogo; conta de forma fora do adaptador
- Guardrail: `derivar` roda na criação, não por passo

---

## Acceptance Criteria

- [x] AC-TG-07 — Eco: `setor` raio 90 px, meio-ângulo 78,46° (±0,01), `centro_a_borda`
- [x] AC-TG-09 (largura/modo) — Anomalia Menor: `retangulo` largura 81 px, `ao_longo_do_eixo` (comprimento contra parede: story-003)
- [x] AC-TG-11 — Fenda 310,6 × 114 (±0,1) desde −57 px; Estilhaço 341,6 × 117; folga do canto 23,6 px
- [x] AC-TG-26 — Eco do Veio 96,75 px; Anomalia do Veio 1945,5 px (câmara livre); Estilhaço 341,6 × 117
- [x] AC-TG-29 — dimensões pelo alvo: Vulto 87, Baluarte 93, jogador 90; faixa no Baluarte 87 × 1731; no Soberano 84 × 1729,5; avanço no Baluarte `R_c` 60, 316,6 × 120

---

## Implementation Notes

- `derivar` é função pura e estática; a tabela `FormasDeTelegrafo` é montada na carga a partir dos `EnemyDef` e injetada.
- Padrões do chefe (`BossPatternDef`) pelo mesmo `derivar`: story-007.

---

## Out of Scope

- story-003: testes de acerto e corte pela parede
- story-007: formas do chefe

---

## Files

- src/gameplay/telegrafos/formas_de_telegrafo.gd
- tests/unit/telegrafos/telegrafos_derivar_test.gd

Fatia: `world_view.gd::_telegraph` e o catálogo JSON usam `tele_raio_px`, `tele_comprimento_max_px`, `tele_largura_px` gravados — **substituir** pela derivação; os campos gravados saem do catálogo na migração (épico assets-e-conteudo).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_derivar_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-001-pool-teto-e-ciclo.md`; épico `production/epics/conteudo/` (`EnemyDef`)
- Unlocks: `production/epics/telegrafos/story-003-forma-e-testes-de-acerto.md`, `story-009-tuning-e-validacao.md`
