# Story 003: Primeiro pacto, escolha da dupla e seed em `dupla_confirmada`

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (B. Primeiro pacto; E. Escolha da dupla; V3, V16, V16b)
**Requirement**: `TR-vinculo-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição; ADR-0005: RNG determinístico; ADR-0012: UI e HUD
**ADR Decision Summary**: `ESCOLHA_DE_ARMA → ESCOLHA_DA_DUPLA` só com Doutrina `pactos` e `vinculo.pedir_dupla()` pedindo tela (≥ 2 pactuadas); com 0 ou 1 o Vínculo responde `dupla_confirmada` na hora (0 → *Vulto Mudo*). A seed nasce só em `→ ATIVA`, depois de `dupla_confirmada`; o estado inicial inclui dupla e perfil. Esc na dupla volta a `ESCOLHA_DE_ARMA` sem seed.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW (ADR-0015, 0005) / HIGH (ADR-0012, só a tela)
**Engine Notes**: Lógica pura; a tela fica na story 010.

**Control Manifest Rules (Feature)**:
- Required: a Run só troca o `EstadoDeJogo` por `pedir_estado`; seed nova só em `→ ATIVA`
- Forbidden: a Run guardar números das Maldições
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-01 (V3): perfil vazio, jogador confirma a Besta → `vulto_mudo` `pactuada = true`, `nivel = 1`, `vinculo_pontos = 0`, `primeiro_pacto_concedido = true`, `pacto_registrado("vulto_mudo")` uma vez e a Run recebe `dupla_confirmada("vulto_mudo", "")` sem abrir a tela de dupla.
- [x] V16/V16b: com ≥ 2 pactuadas `pedir_dupla` pede a tela; Confirmar emite `dupla_confirmada(campo, reserva)` e grava `ultima_dupla`; Voltar retorna a `ESCOLHA_DE_ARMA` sem seed.

---

## Implementation Notes

- Implementar `pedir_dupla(doutrina)` de `PortaDoVinculoNaRun` (ADR-0015 §5).
- `GravadorDePerfil` assina `pacto_registrado` e `dupla_confirmada` (quando houve tela) e só marca pendente.

---

## Out of Scope

- Tela "Escolha do Pacto" e cartão "O Primeiro Vínculo": story 010.

---

## Files

- `src/gameplay/vinculo/vinculo.gd` (`pedir_dupla`), `porta_do_vinculo_na_run.gd`
- `tests/integration/vinculo/primeiro_pacto_e_dupla_test.gd`

Código da fatia: `src/app/main.gd` e `src/gameplay/game_session.gd` não são editados aqui — a composição e as fases da Run são do épico `run-e-regioes`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/vinculo/primeiro_pacto_e_dupla_test.gd`
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-002-perfil-vinculo-e-secao-vinculo.md`; épico `production/epics/run-e-regioes/` (fases da Run)
- Unlocks: `production/epics/vinculo-e-pactos/story-004-sorteio-do-encontro.md`, `production/epics/vinculo-e-pactos/story-010-telas-do-pacto.md`
