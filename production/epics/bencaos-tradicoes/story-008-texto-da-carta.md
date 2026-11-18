# Story 008: Texto da carta com o número da raridade

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R10)
**Requirement**: `TR-bencaos-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Atributos e modificadores (Formatação compartilhada); ADR-0012: UI e HUD
**ADR Decision Summary**: O texto usa `FormulasDeModificadores.formatar_numero_arredondado(valor)` — o mesmo arredondamento do valor aplicado (137,5 → 138) — e nunca `round()`/`snappedf`/`%d` sobre float; o texto vem de chave de tradução.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0009)
**Engine Notes**: Chaves de tradução conforme ADR-0012 (`tr()`); verificar na referência da engine.

**Control Manifest Rules (Feature)**:
- Forbidden: `round()`, `roundi()`, `snappedf` em valores de jogo

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-18: O Muro de Pedras Épico mostra "+50 de Vida máxima"; Rara, "+38 de Vida máxima".
- [x] TR-bencaos-009: a descrição é montada a partir de chave de tradução da `BoonDef` com o número já arredondado; o número mostrado é igual ao aplicado (AC-BN-08).

---

## Implementation Notes

- A Bênçãos entrega a `CartaView` (id, raridade, texto) pronta à Tela; a Tela não recalcula.

---

## Out of Scope

- Épico tela-de-bencao-e-carta: layout da carta

---

## Files

- `src/gameplay/bencaos/texto_da_carta.gd`
- `tests/unit/bencaos/texto_da_carta_test.gd`

Código atual da fatia: textos de bênção no JSON da fatia são **substituídos** por chaves de tradução.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bencaos/texto_da_carta_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-006-escolha-aplicar-e-eventos.md`; `production/epics/modificadores/EPIC.md` (`FormulasDeModificadores` — story a criar)
- Unlocks: None
