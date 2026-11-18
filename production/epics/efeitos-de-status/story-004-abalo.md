# Story 004: Abalo com relógio único e fonte no portador

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R3, R6, F4)
**Requirement**: `TR-status-006`

**ADR Governing Implementation**: ADR-0009: Atributos e modificadores
**ADR Decision Summary**: O Status é o único relógio do Abalo. Na borda `restante 0→>0` aplica a fonte permanente `status:abalo` (multiplicador `1 − reducao_dano_causado`) no portador do inimigo; na borda `>0→0` remove. Reaplicar faz `max` no relógio; a fonte única garante × 0,7, nunca × 0,49. O projétil congela o M no disparo (`DanoCongelado`).
**ADR Version**: ADR-0009 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: arredondamento próprio do ADR-0009 (sem `round()`); nenhuma API pós-cutoff.

**Control Manifest Rules (this layer)**:
- Required: Abalo com um único relógio, no Status (ADR-0009)
- Forbidden: segundo contador de Abalo em Modificadores ou IA
- Guardrail: escrita no portador só nas bordas

---

## Acceptance Criteria

- [x] AC-ST-09 — Abalo 240: `abalado` verdadeiro 0–239, falso depois; reaplicar 30 sobre 200 deixa 200; sobre 10, 30
- [x] AC-ST-10 — Selo nos passos 0–9: `abalado` (lido depois do item 7) verdadeiro até o 37, falso a partir do 38
- [x] AC-ST-11 — com Abalo o dublê do Modificadores devolve 0,7; projétil disparado com Abalo leva 7 de 10 e não muda em voo; disparado 1 passo após o fim, 10

---

## Implementation Notes

- `abalado(inimigo_id) -> bool` é a consulta pública.
- O portador é injetado (dublê nos testes); só `aplicar_fonte`/`remover_fonte` nas bordas.

---

## Out of Scope

- story-005: Abalo vindo das Maldições

---

## Files

- src/gameplay/status/modulo_de_status.gd
- tests/unit/status/status_abalo_test.gd

Fatia: nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status/status_abalo_e_fontes_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/efeitos-de-status/story-001-modelo-e-aplicar.md`; épico `production/epics/modificadores/` (Portador e fontes)
- Unlocks: `production/epics/efeitos-de-status/story-005-fontes-e-maldicoes.md`
