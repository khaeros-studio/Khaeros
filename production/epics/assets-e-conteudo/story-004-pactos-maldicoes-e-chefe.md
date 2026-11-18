# Story 004: Dados da Doutrina de Pactos — CurseDef, chefe (BossPatternDef) e tunings de Pactos

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R1-P); `design/gdd/maldicoes.md` (catálogo); `design/gdd/vinculo-e-pactos.md`; `design/gdd/chefes.md`
**Requirement**: N/A — sem TR próprio; validado por TR-maldicoes-*, TR-vinculo-*, TR-chefes-001 (ML1–ML8, VP1–VP9, CH1–CH8).
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (emenda 2026-11-16, Doutrina de Pactos)
**ADR Decision Summary**: 4 `CurseDef` no MVP (`vulto_mudo`, `espreitador_da_fenda`, `baluarte_de_cinza`, `soberano_do_limiar`) com ids append-only (chave do perfil salvo) e ordem estável que só cresce no fim; `BossPatternDef` embutido em `padroes` do `EnemyDef` do chefe; `MaldicoesTuning`, `VinculoTuning`, `ChefesTuning`; `RunTuning.camaras_jogaveis` 7, `arma_padrao` aceita `pactos`; `RegionDef limiar` com `chefe = soberano_do_limiar`.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `TecnicaDef` (ADR-0017) ainda não está na R1-P do Conteúdo — **não** criar até o dono do formato confirmar (ADR-0004 emenda).

**Control Manifest Rules (Foundation)**:
- Required: ids de `CurseDef` append-only; ordem no manifesto só cresce no fim
- Forbidden: reaproveitar id de `CurseDef`
- Guardrail: validação ≤ 30 ms

---

## Acceptance Criteria

*From ADR-0004 emenda Pactos and the owners' catalogs:*

- [x] Os 4 `CurseDef` com os ids exatos acima, na ordem acima, com valores do catálogo de Maldições (Soberano: `total_exausta` 480, Passiva 2).
- [x] `EnemyDef soberano_do_limiar` com `padroes: Array[BossPatternDef]` embutidos, na ordem do GDD de Chefes.
- [x] `MaldicoesTuning`, `VinculoTuning` (inclui `chance_encontro`, `pity_runs`, `indices_encontro`, `frac_vida_acuada`) e `ChefesTuning` com os padrões dos GDDs; `HudTuning` com HU15–HU17.
- [x] Carregador chega a Pronto com ML/VP/CH sem erro; smoke check registrado.

---

## Implementation Notes

*Derived from ADR-0004 emenda Pactos:*

- `CurseDef soberano_do_limiar` e `EnemyDef soberano_do_limiar` compartilham id em tipos diferentes (índice por (tipo, id)).
- Nada de Pactos passa por `mapa_ids.csv`.

---

## Out of Scope

- Story 007: arte das Maldições e do chefe

---

## Files

- `assets/data/maldicoes/*.tres`, `assets/data/inimigos/soberano_do_limiar.tres`, `assets/data/tuning/{maldicoes,vinculo,chefes}_tuning.tres` (novos); `assets/data/content_catalog.tres`, `assets/data/tuning/{run,hud}_tuning.tres`, `assets/data/regioes/limiar.tres` (acrescentar/ajustar)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`)
**Status**: [x] Created (`production/qa/evidence/assets-e-conteudo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/assets-e-conteudo/story-003-bencaos-regioes-e-camaras.md`; `production/epics/conteudo/` (tipos `CurseDef`, `BossPatternDef` e regras ML/VP/CH)
- Unlocks: `production/epics/assets-e-conteudo/story-005-canon-csv-paridade-e-aposentar-json.md`
