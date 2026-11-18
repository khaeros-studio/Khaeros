# Story 008: Linhas de oferta, bênção, porta e morte

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R4)
**Requirement**: `TR-telemetria-003` (oferta, porta, causa da morte)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos
**ADR Decision Summary**: Cada linha nasce de um evento da lista do passo; campos ainda não emitidos pelos donos (causa da morte, porta escolhida) saem `null` sem falha até existirem.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH
**Engine Notes**: —

**Control Manifest Rules (Presentation)**:
- Required: Telemetria é `ConsumidorDeEventos` puro
- Forbidden: escrever no jogo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-08 (R4): `oferta_aberta` com 3 cartas grava `oferta` (3 `id` + `raridade`, `trocas`); `oferta_trocada` grava `oferta_trocada`; `bencao_tomada` grava `bencao` com `trocas_restantes`.
- [x] AC-TL-09 (R4): porta escolhida grava `porta` com o `tipo` escolhido e as `opcoes`.
- [x] AC-TL-10 (R4): `jogador_morreu` grava `morte` com `causa` (`tipo_inimigo`, `ataque`) quando o Combate fornece e `causa: null` (sem `TL3`) quando não; `recusou_morte` não grava `morte` e o `dano_recebido` soma o `vida_perdida` sem descontar a recuperação.

---

## Implementation Notes

- Os campos novos pedidos ao Combate e às Portas são contratos dos épicos donos; aqui só se lê.

---

## Out of Scope

- Linhas de Pactos: story 009.

---

## Files

- `src/presentation/telemetria/linhas_de_eventos.gd`
- `tests/unit/telemetria/oferta_porta_e_morte_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/oferta_porta_e_morte_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/oferta_porta_e_morte_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-007-linha-de-camara-e-contadores.md`; épicos `production/epics/bencaos-tradicoes/`, `production/epics/portas-e-recompensas/`, `production/epics/combate-nucleo/`
- Unlocks: `production/epics/telemetria-local/story-010-run-completa-e-pior-passo.md`
