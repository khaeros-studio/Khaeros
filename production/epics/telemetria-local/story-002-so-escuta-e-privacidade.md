# Story 002: Só escuta, o jogo nunca lê, e privacidade

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R1, R7, R13)
**Requirement**: `TR-telemetria-002`, `TR-telemetria-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos; ADR-0013: Persistência do MVP
**ADR Decision Summary**: A Telemetria só consome a lista `EventosDoPasso` (primeira na entrega); escritor, armazém e relógio injetados. Nunca ler o `.jsonl` no jogo, nem escrever caminho absoluto, nome de usuário ou hora local; data em UTC; sem rede; não criar telemetria num cliente co-op.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0002) / MEDIUM (ADR-0013)
**Engine Notes**: —

**Control Manifest Rules (Presentation)**:
- Required: a Apresentação só lê e nunca escreve no jogo
- Forbidden: chamar método de escrita de qualquer sistema
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-14 (R1, R13): a Telemetria não chama método de escrita de nenhum sistema; roda com eventos e escritor falsos, sem disco.
- [x] AC-TL-17 (R7): nenhuma linha contém nome do usuário, caminho absoluto, IP, nome da máquina ou hora local com fuso; `data_utc` termina em `Z`; `seed` (hex em debug) e `impressao` só com os caracteres esperados.
- [x] AC-TL-30 (R1): nenhum símbolo de leitura do arquivo é chamado fora do leitor de teste (varredura do módulo).

---

## Implementation Notes

- A varredura de AC-TL-30 é um teste que lê o código-fonte do módulo e procura `get_line`, `get_as_text`, `open(... READ)` etc.

---

## Out of Scope

- Leitor de teste das fixtures: story 010.

---

## Files

- `src/presentation/telemetria/telemetria.gd`
- `tests/unit/telemetria/so_escuta_e_privacidade_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/so_escuta_e_privacidade_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/so_escuta_e_privacidade_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-001-sessao-arquivo-e-campos-comuns.md`; épico `production/epics/orquestrador-do-passo/` (`ConsumidorDeEventos`)
- Unlocks: None
