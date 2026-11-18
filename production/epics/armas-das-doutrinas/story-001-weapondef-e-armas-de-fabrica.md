# Story 001: WeaponDef, AttackDef e as três armas de fábrica

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (R1, R2, R2b; AC l.1237–1308, l.1742–1752)
**Requirement**: `TR-armas-001`, `TR-armas-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0010: Resolução do combate no passo
**ADR Decision Summary**: `WeaponDef` com exatamente 7 campos e `AttackDef` como sub-recurso, no catálogo .tres com manifesto explícito; propriedade desconhecida é erro; a arma não tem regra própria em código — tudo vem das formas e params do `AttackDef`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0004: `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (4.5) — constante fora de `docs/engine-reference/`, confirmada só no experimento de 2026-11-14 (NEEDS VERIFICATION no caso completo).

**Control Manifest Rules (this layer)**:
- Required: módulos criados por `ComposicaoDaSessao`/`FabricaDaRun`, dependências no `_init`
- Forbidden: Autoload, `get_node` absoluto em lógica
- Forbidden (Core, consumidor): mutar `params` do catálogo depois de criado

---

## Acceptance Criteria

- [x] AC-AR-01 [L] R1 — os 7 campos (l.1237)
- [x] AC-AR-02 [L] R2 — Lâmina do Juramento, carregada do catálogo de fábrica (l.1248)
- [x] AC-AR-03 [L] R2 — Foco Ressonante, carregado do catálogo de fábrica (l.1257)
- [x] AC-AR-04 [L] R2 — conversões do cânone (l.1265)
- [x] AC-AR-05 [L] recuperação derivada (Combate F2) (l.1281)
- [x] AC-AR-07 [L] R1 — arma sem regra própria (l.1300)
- [x] AC-AR-41 [L] R2b — Besta do Vínculo, carregada do catálogo de fábrica (l.1742)
- [x] AC-AR-42 [L] Combate F2 — recuperação da Besta (l.1750)

---

## Implementation Notes

*Derived from ADR-0004 and ADR-0010:*

- `WeaponDef`/`AttackDef` são `Resource` com `class_name`, no manifesto do catálogo; cópia entregue ao Combate por `duplicate_deep`.
- Nenhum `if arma == ...` em código: forma, dano, empurrão, recarga vêm do `AttackDef`.
- **Código da fatia**: Lâmina (combo, golpe pesado, estocada) em `src/gameplay/game_session.gd` e números em `src/foundation/session_catalog.gd` — **substituir** por `.tres`; usar como referência de sensação.

---

## Out of Scope

- Story 002: validação cruzada AV1–AV9
- Story 006: comportamento do Virote/Chamado

---

## Files

- `src/content/defs/weapon_def.gd`, `src/content/defs/attack_def.gd`, `src/content/defs/armas_tuning.gd`
- `assets/data/armas/lamina_do_juramento.tres`, `foco_ressonante.tres`, `besta_do_vinculo.tres`, `armas_tuning.tres`
- `tests/unit/weapons/weapondef_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/armas/weapondef_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-001-combat-tuning-e-esqueleto.md`, `production/epics/conteudo/EPIC.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-002-validacao-das-armas.md`, `production/epics/armas-das-doutrinas/story-003-formulas-de-referencia.md`, `production/epics/armas-das-doutrinas/story-004-arma-da-run-e-injecao.md`
