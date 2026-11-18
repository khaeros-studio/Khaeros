# Story 002: RunTuning e RegionDef no catálogo, validação RN1–RN3

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (Tuning Knobs; validação RN1–RN3)
**Requirement**: `TR-run-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: catálogo `.tres` com manifesto explícito e validadores; erro impede a run de começar.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: MEDIUM
**Engine Notes**: `Resource` imutável; cópia mutável só por `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`.

**Control Manifest Rules (this layer)**:
- Required: esquema declara campos, tipos, limites e regras entre campos; distingue ausente de gravado (ADR-0004)
- Forbidden: número de jogo literal na Run

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-38** `arma_padrao = pactos` é aceito; `camaras_jogaveis` 8: RN3; última jogável `santuario`: RN2; última `chefe`: válido.
- [x] **AC-RN-24 (parte vigente)** Arma inválida: RN1; `camaras_jogaveis` 0, ou região sem combate jogável: RN3.
- [x] Fábrica: `RegionDef limiar` com 7 câmaras (combate ×3, santuário, combate ×2, chefe), `RunTuning` com `fragmentos_vitoria` 15 e `arma_padrao` Lâmina, sem erro nem aviso.

---

## Implementation Notes

*Derived from ADR-0004 / ADR-0015 §4:*

- `RunTuning` e `RegionDef` são `Resource`s do manifesto; RN1–RN3 registrados no validador do catálogo.
- A Run recebe ambos já validados por injeção.

---

## Out of Scope

- Story 003: uso da sequência.

---

## Files

- `assets/data/tuning/run_tuning.tres`, `assets/data/regioes/limiar.tres`
- `src/gameplay/run/run_tuning.gd`, `src/gameplay/run/region_def.gd`, `src/gameplay/run/validacao_run.gd`
- `tests/integration/run/run_validacao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/run/run_validacao_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: épico `production/epics/conteudo/EPIC.md` (validador do catálogo); épico `production/epics/armas-das-doutrinas/EPIC.md` (`WeaponDef` para RN1)
- Unlocks: `production/epics/run-e-regioes/story-003-sequencia-da-regiao.md`

**Código da fatia**: `session_catalog.gd` lê JSON; os dados de run migram para o catálogo `.tres` do épico `conteudo` — **substituir** a leitura correspondente.
