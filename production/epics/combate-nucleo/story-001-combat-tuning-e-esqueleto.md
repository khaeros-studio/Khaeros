# Story 001: CombatTuning validado e esqueleto injetável do Combate

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (Formulas › Faixas do `CombatTuning` l.1267; Validação l.1306; AC l.2106–2166, l.2919–3022)
**Requirement**: `TR-combate-nucleo-003`, `TR-combate-nucleo-015`, `TR-combate-nucleo-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0004: Catálogo de dados; ADR-0003: Entidades e portadores; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: O Combate é lógica pura (RefCounted) com todas as dependências injetadas (portadores, amostra, consultas, geometria, tuning, AttackDef); os valores vêm do `CombatTuning` .tres validado no catálogo (CV1–CV21) e copiado por `duplicate_deep`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0004: `Resource.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` é pós-corte (4.5); a constante não está em `docs/engine-reference/` (confirmada só no experimento de 2026-11-14). ADR-0010: `@abstract` (4.5) nas bases de contratos; override com retorno tipado exige `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: tudo em `float` até o fim de F1/F2/F3, arredondar só por `arredondar_meio_longe_do_zero` (ADR-0009/0010)
- Forbidden: `Area2D`/`ShapeCast2D`, consulta de física, `Timer`, `Engine.time_scale` ou sinal do Godot na regra de combate
- Guardrail: Combate ≤ 0,3 ms p99 por passo vivo (medido na story 010)

---

## Acceptance Criteria

*From GDD `design/gdd/combate-nucleo.md` (texto integral nas linhas citadas):*

- [x] AC-01 [L] R15 — conversões (l.2106)
- [x] AC-02 [L] R16 — determinismo sem SceneTree (l.2115)
- [x] AC-03 [L] faixas do `CombatTuning` (l.2125)
- [x] AC-04 [L] R16/Dados — sem valor escondido (l.2161)
- [x] AC-60 [L] CV1/CV2/CV21 — hitstop (l.2919)
- [x] AC-61 [L] CV3/CV4/CV5 — combo (l.2937)
- [x] AC-62 [L] CV6/CV7/CV8 — empurrão (l.2953)
- [x] AC-63 [L] CV9/CV10/CV11/CV13/CV15 — limites de um campo (l.2973)
- [x] AC-64 [L] CV12/CV14/CV16–CV20 — validações cruzadas (l.2987)
- [x] AC-65 [I] erros e avisos chegam ao destino (l.3011)

---

## Implementation Notes

*Derived from ADR-0010, ADR-0004 and ADR-0003:*

- `Combate extends RefCounted`; todas as dependências no `_init` (TR-015). Nada de Autoload, `get_node` absoluto ou SceneTree na regra.
- Estado vivo (inimigos, projéteis, `RecursosDoJogador` por `player_id`) fora do SceneTree, em ordem estável (TR-003). Vida, escudo, cargas, contador de acertos e janela pós-esquiva nunca no portador.
- `CombatTuning` é recurso do catálogo (manifesto explícito, validação CV1–CV21 na carga, impressão SHA-256), entregue ao Combate como cópia por `duplicate_deep`. Conversões s→passos na carga (R15).
- **Código da fatia**: `src/foundation/session_catalog.gd` — **substituir** pela entrada `CombatTuning` do catálogo (épico `conteudo`); os números da fatia (`game_session.gd`) servem só de referência para o `.tres` de fábrica, conferidos contra as faixas do GDD.

---

## Out of Scope

- Story 002: ordem do passo e hitstop
- Épico `conteudo`: carregador do catálogo, manifesto e impressão

---

## Files

- `src/gameplay/combate/combate.gd` (esqueleto, injeção)
- `src/gameplay/combate/recursos_do_jogador.gd`
- `src/content/defs/combat_tuning.gd`, `src/content/validacao/validador_combat_tuning.gd`
- `assets/data/combat_tuning.tres`
- `tests/unit/combat/combat_tuning_test.gd`, `tests/unit/combat/combate_injecao_test.gd`
- `tests/integration/combat/combat_tuning_relatorio_test.gd` (AC-65)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/combat_tuning_test.gd` — must exist and pass; AC-65 em `tests/integration/combat/combat_tuning_relatorio_test.gd`

**Status**: [x] Complete (`src/gameplay/combate/validador_combat_tuning.gd`, `tests/unit/combat/combat_tuning_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/conteudo/EPIC.md` (carregador do catálogo), `production/epics/modificadores/EPIC.md` (portador e `arredondar_meio_longe_do_zero`), `production/epics/orquestrador-do-passo/EPIC.md`
- Unlocks: todas as stories 002–010 deste épico; `production/epics/armas-das-doutrinas/story-001-weapondef-e-armas-de-fabrica.md`
