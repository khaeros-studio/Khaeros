# Story 003: Definições de bênçãos (BoonDef), regiões e câmaras/ondas

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R1); `design/gdd/bencaos-tradicoes.md`; `design/gdd/camaras-e-ondas.md`; `design/gdd/run-e-regioes.md`; `design/gdd/tela-de-bencao-e-carta.md` R2 (campos da carta)
**Requirement**: N/A — sem TR próprio; validado pelos TRs de `bencaos-tradicoes`, `camaras-e-ondas`, `run-e-regioes` e `TR-tela-bencao-002`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Definições por tipo na ordem do manifesto (a ordem participa dos sorteios reproduzíveis); textos visíveis como chaves de tradução, preço com marcador `{valor}` (V10); caminhos de arte como texto validados por V7.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: —

**Control Manifest Rules (Foundation)**:
- Required: esquema com campos, tipos, limites; validação distingue ausente de gravado
- Forbidden: importador em runtime
- Guardrail: validação ≤ 30 ms

---

## Acceptance Criteria

*From the epic scope and GDD Tela R2:*

- [x] `BoonDef` das Tradições do MVP com `glifo`, `icone_ganho` e chave de preço com `{valor}` (só O Preço com Nome tem custo); nenhum número literal em texto (V10).
- [x] `RegionDef limiar` (com `chefe = soberano_do_limiar` preenchido na story 004) e as definições de câmaras/ondas da fatia migradas de `gameplay.json` com os mesmos valores.
- [x] Carregador chega a Pronto; impressão curta registrada no smoke check.

---

## Implementation Notes

*Derived from ADR-0004:*

- A ordem dos `BoonDef` no manifesto afeta o sorteio; congelar a ordem atual da fatia.

---

## Out of Scope

- Story 004: Pactos e chefe
- Story 008: glifos e ícones como arte

---

## Files

- `assets/data/bencaos/*.tres`, `assets/data/regioes/*.tres`, `assets/data/camaras/*.tres` (novos); `assets/data/content_catalog.tres` (acrescentar)
- `assets/i18n/conteudo.csv` (chaves `BOON_*`)

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

- Depends on: `production/epics/assets-e-conteudo/story-002-armas-ataques-e-inimigos.md`
- Unlocks: `production/epics/assets-e-conteudo/story-004-pactos-maldicoes-e-chefe.md`
