# Story 007: Linha de câmara — contadores, duração em passos de Jogo e morte no mesmo passo

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R4, R5, F1)
**Requirement**: `TR-telemetria-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Passo fixo de 60 Hz com estado de jogo próprio; a duração da câmara conta passos em estado Jogo, incluindo o hitstop, e não conta pausa nem Bênção.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH
**Engine Notes**: Sem `SceneTree.paused`; o estado vem do orquestrador.

**Control Manifest Rules (Presentation)**:
- Required: guiada por `t_vivo`/passos do orquestrador, sem relógio próprio
- Forbidden: escrever no jogo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-05 (R4, R5): câmara com `jogador_atingido` (perdida 8 e 12; um golpe de 6 absorvido pelo escudo) e 3 `inimigo_morreu` → `dano_recebido = 20`, `abates = 3`, `resultado = limpa`.
- [x] AC-TL-06 (F1, R5): 1 044 passos em Jogo (com 30 de hitstop), 600 de pausa e 120 de Bênção → `duracao_s = 17,40`.
- [x] AC-TL-07 (R5): santuário → `tipo = santuario`, `dano_recebido = 0`, `abates = 0`.
- [x] AC-TL-29 (R5): `jogador_morreu` e `camara_limpa` no mesmo passo → uma só `camara` com `resultado = morte`.

---

## Implementation Notes

- `passos_em_jogo()` lido do orquestrador (ADR-0015 guarda o inicial).

---

## Out of Scope

- `morte` e `recusou_morte`: story 008.

---

## Files

- `src/presentation/telemetria/linha_de_camara.gd`
- `tests/unit/telemetria/linha_de_camara_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/linha_de_camara_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/linha_de_camara_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-006-linhas-de-run-seed-e-impressao.md`; épicos `production/epics/camaras-e-ondas/`, `production/epics/combate-nucleo/` (eventos)
- Unlocks: `production/epics/telemetria-local/story-010-run-completa-e-pior-passo.md`
