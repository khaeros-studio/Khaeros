# Story 007: Consulta (obter, existe, listar, filtrar), ordem do manifesto e cópia mutável

> **Epic**: conteudo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R3, R10, R10-P)
**Requirement**: `TR-conteudo-003` (só leitura; `duplicate_deep`), `TR-conteudo-010` (consulta por injeção), `TR-conteudo-019` (ordem estável do manifesto de `CurseDef`)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0003, ADR-0005)
**ADR Decision Summary**: Consultas por id usam o índice; listar/filtrar usam a lista na ordem do manifesto; obsoletos resolvem por id e saem de listar/filtrar por padrão; listas retornadas protegem a estrutura interna; cópia mutável com sub-recursos usa `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `duplicate_deep()` é 4.5; o nome da constante `DEEP_DUPLICATE_ALL` deve estar confirmado por EX-0004-NV (story 002 de experimentos).

**Control Manifest Rules (this layer)**:
- Required: módulos recebem o catálogo (ou a parte) por injeção; ordem do manifesto estável; cópia fora do catálogo.
- Forbidden: singleton de catálogo; mutar definição do catálogo.
- Guardrail: consulta O(1) por id.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-22: manifesto na ordem `c, a, b`: listar e filtrar repetidas vezes, e com o catálogo reconstruído, devolvem sempre `c, a, b`.
- [x] AC-23: seed fixa e o mesmo catálogo: um sorteio que usa as listas roda duas vezes com sequências idênticas.
- [x] AC-25: definição copiada com `duplicate_deep()`; alterar a cópia deixa a do catálogo igual ao snapshot anterior.
- [x] AC-26: `AttackDef` compartilhado por duas armas não dá erro de validação.
- [x] AC-27: definição `obsoleto = true` é devolvida por `obter`; `listar`/`filtrar` sem parâmetro não a incluem; com o parâmetro explícito, incluem.
- [x] AC-60 (parte): os 4 `CurseDef` saem de `listar` na ordem do manifesto (ordem estável; só cresce no fim).
- [x] Listas devolvidas são cópias: mutá-las não altera o catálogo.

---

## Implementation Notes

`Catalogo` com `obter(tipo,id)`, `existe`, `listar(tipo, incluir_obsoletos := false)`, `filtrar(tipo, predicado, incluir_obsoletos := false)`, `impressao_completa()`/`impressao_curta()` (preenchidas pela story 008). Relator injetado da story 001. `copiar_mutavel(def)` usa a constante confirmada em EX-0004-NV. AC-24 (sem `load()` fora do carregador) está na story 003.

---

## Out of Scope

- Impressão (008), recarga (009), validação (004/006).

---

## Files

- `src/content/catalogo.gd`
- `tests/unit/content/consulta_e_copia_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/consulta_e_copia_test.gd` — must exist and pass.

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `story-001-esquema-e-relator.md`, `story-003-carregador-e-manifesto.md`, `production/epics/experimentos-de-engine/story-002-catalogo-e-cena.md`
- Unlocks: todos os épicos que consultam o catálogo; `production/epics/rng/` (sorteios sobre listas)

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

`src/content/catalogo.gd`: `filtrar(tipo, predicado, incluir_obsoletos)`, `copiar_mutavel()` estático (`duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`, constante já exercitada no 4.7.2 pelo teste da story 002), `definir_impressao`/`impressao_completa`/`impressao_curta`; listas devolvidas são cópias. Teste `tests/unit/content/consulta_e_copia_test.gd`: 7 casos, 7 passaram (AC-22, AC-23 com LCG de teste em vez do RNG do jogo, AC-25, AC-26, AC-27, AC-60 parte, listas-cópia).
Pendência: AC-23 com o `FluxoRng` real é do épico rng.
