# Story 008: Chefe subjugado — Pactuar ou Exorcizar

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (V18, V18.5)
**Requirement**: `TR-vinculo-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição; ADR-0002: Canal de eventos; ADR-0012: UI e HUD
**ADR Decision Summary**: Em Pactos, o Combate marca `Subjugado`, os Chefes emitem `EvChefeSubjugado`, a Run liga `chefe_subjugado_pendente`; Interagir no chefe abre a tela no estado Bênção; a escolha emite `chefe_escolhido` e, em Pactuar, `pacto_registrado`. O pacto com o chefe não chama `acrescentar_a_dupla`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW (ADR-0015) / HIGH (ADR-0002, 0012)
**Engine Notes**: —

**Control Manifest Rules (Feature)**:
- Required: variante `ChefesNulo`/`VinculoNulo` com `return` explícito
- Forbidden: Autoload, `get_node` absoluto
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-22 (V18): chefe `Subjugado` e *Soberano* não pactuado, Pactuar → espécie `pactuada`, nível 1, `pacto_registrado("soberano_do_limiar")` e `chefe_escolhido("soberano_do_limiar", "pactuar")`; os Chefes creditam 0.
- [x] AC-VP-23 (V18.5): *Soberano* nível 5 e dupla *Vulto* (2) e *Espreitador* (5), Pactuar → o *Vulto* ganha 10 pontos da run e os 10 do *Espreitador* vão para o *Baluarte* (menor nível fora da dupla).

---

## Implementation Notes

- Exorcizar credita `+6` Fragmentos pelo épico `chefes`/`economia-de-fragmentos`; o Vínculo só emite `chefe_escolhido(..., "exorcizar")`.

---

## Out of Scope

- Tela Pactuar/Exorcizar: story 010. Desfecho do chefe e crédito: épico `production/epics/chefes/`.

---

## Files

- `src/gameplay/vinculo/escolha_do_chefe.gd`
- `tests/integration/vinculo/chefe_pactuar_ou_exorcizar_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/vinculo/chefe_pactuar_ou_exorcizar_test.gd`
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-007-pontos-niveis-e-consolidacao.md`; épico `production/epics/chefes/` (`EvChefeSubjugado`)
- Unlocks: `production/epics/vinculo-e-pactos/story-010-telas-do-pacto.md`
