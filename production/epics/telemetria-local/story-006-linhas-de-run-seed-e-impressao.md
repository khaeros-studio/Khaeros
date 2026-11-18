# Story 006: Linhas de run — `run_iniciada`, `run_encerrada`, abandono, nova run, seed e impressão

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R4, R12)
**Requirement**: `TR-telemetria-003` (eventos de run), `TR-telemetria-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos; ADR-0005: RNG determinístico; ADR-0004: Catálogo de dados
**ADR Decision Summary**: As linhas nascem dos eventos da lista do passo (`EvRunEncerrada` e o início da run). A seed (64 bits, texto hex) vem do RNG; a impressão do catálogo é SHA-256 (64 hex na linha de run, 4 hex na de sessão).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0002) / LOW (ADR-0005) / MEDIUM (ADR-0004)
**Engine Notes**: —

**Control Manifest Rules (Presentation)**:
- Required: só leitura do `ResumoDaRun` (sem setters, arrays read-only)
- Forbidden: escrever no jogo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-04 (R4): ao criar a seed grava `run_iniciada` com `seed` (texto), `impressao` (64 hex), `regiao` e `estado_inicial` (`arma`, `doutrina`, `oficina` vazia); `run = 1` na 1ª run.
- [x] AC-TL-11 (R4, R12): `run_encerrada` grava o resumo de 10 campos da Run R7, o `caminho` em ordem e `fragmentos_por_origem`; vitória, morte e abandono geram uma linha cada.
- [x] AC-TL-12 (R12): abandono na câmara 2 → `camara` com `resultado = abandono`, depois `run_encerrada` com motivo `abandono`.
- [x] AC-TL-13 (R12): `run_encerrada` vem antes de `run_iniciada`; `run` passa de 1 para 2.
- [x] AC-TL-33 (R4): a 1ª `camara` traz `ms_inicio`; `ms_inicio − ms(run_iniciada)` é o tempo do "Jogar" à 1ª câmara.

---

## Implementation Notes

- `ResumoDaRun` e `LeituraDaConta` (ADR-0015) são as fontes do resumo e dos Fragmentos.

---

## Out of Scope

- Resumo de 12 campos e campos de Pactos: story 009.

---

## Files

- `src/presentation/telemetria/linhas_de_run.gd`
- `tests/unit/telemetria/linhas_de_run_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/linhas_de_run_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/linhas_de_run_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-001-sessao-arquivo-e-campos-comuns.md`; épicos `production/epics/run-e-regioes/` (eventos e `ResumoDaRun`), `production/epics/rng/`
- Unlocks: `production/epics/telemetria-local/story-009-schema-2-pactos.md`
