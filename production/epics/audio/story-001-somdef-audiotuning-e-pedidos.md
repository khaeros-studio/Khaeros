# Story 001: SomDef, AudioTuning, PedidoDeSom e FilaDeSonsDeInterface

> **Epic**: Áudio: ganchos e vozes
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Os tipos de dados do áudio: `SomDef` (id = gancho, `caminho_stream`, `ganho_db`, `variacoes`), `AudioTuning` (vozes e pitch do tom), o `PedidoDeSom` que Feedback e Telas criam, e a `FilaDeSonsDeInterface` pré-alocada. O épico não tem GDD próprio: os critérios vêm do ADR-0016 (Validation Criteria) e dos GDDs de Feedback e Telégrafos.

**GDD**: `docs/architecture/adr-0016-audio-ganchos-e-vozes.md` (sem GDD próprio; requisitos de `design/gdd/feedback-de-combate.md` e `design/gdd/telegrafos.md`)
**Requirement**: `TR-feedback-008` (valores de `AudioTuning` cujo dono semântico é o Feedback F4)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes; ADR-0004: Catálogo de dados
**ADR Decision Summary**: `SomDef` e `AudioTuning` entram no catálogo; nenhum caminho literal de som; variação round-robin por gancho, sem RNG de jogo; gancho sem `SomDef` ou stream que não carrega = silêncio e `FB2` uma vez por gancho por run.
**ADR Version**: ADR-0016 2026-11-16; ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Só `Resource`/`RefCounted`; nenhuma API NOT SOURCEABLE aqui.

**Control Manifest Rules (this layer)**:
- Required: todo stream vem de `SomDef` do catálogo; entrega sem alocar (arrays pré-alocados)
- Forbidden: never caminho literal de som; never guardar `PedidoDeSom` além da entrega
- Guardrail: áudio < 0,05 ms por passo

---

## Acceptance Criteria

*From ADR-0016 §7 / Key Interfaces and `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] `SomDef` e `AudioTuning` validados na carga do catálogo; `AudioTuning` com `vozes_max_gancho` 4 e `vozes_max_total` 16 (Feedback F4), `vozes_interface` 4, `teto_tons_telegrafo` 3, `tom_pitch_min` 1,0, `tom_pitch_max` 2,0
- [x] AC-FB-25 [L] Edge — cláusula `FB2` (gancho sem som: silêncio e `FB2`), uma vez por gancho por run (ADR-0016 §7)
- [x] `FilaDeSonsDeInterface.pedir()` + `drenar_para(saida)` sem alocar, devolvendo quantos; a fila fica vazia após drenar
- [x] Variações round-robin por gancho: a mesma sequência de pedidos escolhe as mesmas variações

---

## Implementation Notes

*Derived from ADR-0016 §7 and Implementation Guidelines:*

- `PedidoDeSom` com `gancho: StringName`, `prioridade: int` (0 = P0 … 4 = P4), `player_id: int`.
- A resolução `SomDef` → `AudioStream` acontece na construção da run (story 004), não aqui.

---

## Out of Scope

- Story 002 Mixador; 003 Seletor; 004 nó

---

## Files

- `src/content/som_def.gd`, `src/content/audio_tuning.gd`
- `src/presentation/audio/pedido_de_som.gd`, `fila_de_sons_de_interface.gd`
- `tests/unit/audio/somdef_audiotuning_e_pedidos_test.gd`

Código da fatia: nenhum (construção do zero).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/audio/somdef_audiotuning_e_pedidos_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/audio/somdef_audiotuning_e_pedidos_test.gd`, `production/qa/evidence/audio-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/conteudo/EPIC.md` (catálogo ADR-0004)
- Unlocks: `production/epics/audio/story-002-mixador-de-vozes.md`, `production/epics/audio/story-003-seletor-de-tons-dos-telegrafos.md`, `production/epics/feedback-de-combate/story-007-respostas-das-maldicoes.md`
