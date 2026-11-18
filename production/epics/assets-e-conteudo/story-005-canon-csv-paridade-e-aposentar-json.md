# Story 005: CSV canônico, paridade de importação e aposentar o gameplay.json

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R5 pasta canônica, tabelas F1–F6)
**Requirement**: N/A — sem TR próprio; fornece os dados que `TR-conteudo-014` (paridade) e `TR-conteudo-015` (tempo de carga) verificam no épico `conteudo`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (emenda 2026-11-16, importação e paridade)
**ADR Decision Summary**: `tools/content-import/` converte as tabelas do cânone (CSV em `assets/data/canon/`, importador `keep`, excluído do export) em `.tres` na ordem do manifesto, só em editor/CI. O teste de paridade em `tests/integration/content/` importa, carrega pelo carregador de produção e compara campo a campo mais a impressão completa; divergência falha o CI.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: CSV com importador `keep` excluído do export e legível em editor/CI — NEEDS VERIFICATION (ADR-0004 Verification Required 3).

**Control Manifest Rules (Foundation)**:
- Required: importação CSV→`.tres` por `tools/content-import/`, só em editor/CI; teste de paridade em `tests/integration/content/`
- Forbidden: executar o importador em runtime
- Guardrail: carga fria mediana ≤ 250 ms, validação ≤ 30 ms

---

## Acceptance Criteria

*From ADR-0004 emenda and the epic scope:*

- [x] `assets/data/canon/*.csv` contém as tabelas F1–F6 com os mesmos valores dos `.tres` das stories 001–004.
- [x] Teste de paridade passa (campo a campo + impressão completa).
- [x] `data/integration/gameplay.json` deixa de ser lido: `session_catalog.gd` e `game_session.gd` leem só o catálogo; o arquivo é removido (ou marcado obsoleto) sem quebrar a fatia jogável.
- [x] Captura da fatia rodando com o catálogo novo em `production/qa/evidence/`.

---

## Implementation Notes

*Derived from ADR-0004:*

- O script de importação é de `tools-programmer` (ADR-0004); esta story entrega os CSVs e roda a paridade.

---

## Out of Scope

- Épico `conteudo`: o script `tools/content-import/` e o harness de performance

---

## Files

- `assets/data/canon/*.csv` (novos)
- `src/foundation/session_catalog.gd`, `src/gameplay/game_session.gd` (adaptar: ler do catálogo; depois substituídos pelos módulos reais)
- `data/integration/gameplay.json` (aposentar)
- `tests/integration/content/paridade_canon_test.gd` (se o épico `conteudo` ainda não o criou)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/content/paridade_canon_test.gd` passando
**Status**: [x] Created (`production/qa/evidence/assets-e-conteudo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/assets-e-conteudo/story-004-pactos-maldicoes-e-chefe.md`; `production/epics/conteudo/` (story do script de importação e do teste de paridade)
- Unlocks: None
