# Story 006: Número agregado e consulta estado(inimigo)

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R6, R8, F5)
**Requirement**: `TR-status-009`, `TR-status-012`

**ADR Governing Implementation**: ADR-0011: Pipeline visual (§8); ADR-0002: Canal de eventos; ADR-0003: Entidades e portadores
**ADR Decision Summary**: O Status conta o período do número em passos vivos por inimigo, com resto acumulado, e emite o valor pronto como evento; o `PoolDeNumeros` só mostra na faixa `status` e anima em `t_apres`. `estado(inimigo)` é consulta pura por valor (acúmulos e `restante`); a vista limita a 3 sinais e a 1 com > 9 marcados.
**ADR Version**: ADR-0011 2026-11-16 · ADR-0002 2026-11-16 · ADR-0003 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0011; o lado Status é lógica pura, LOW)
**Engine Notes**: o Status não toca nó; nenhuma API de engine aqui.

**Control Manifest Rules (this layer)**:
- Required: consultas devolvem valores desvinculados (ADR-0003)
- Forbidden: expor o registro interno; Status animar
- Guardrail: evento de número só no fim do período

---

## Acceptance Criteria

- [x] AC-ST-19 — A_s 10 + A_q 6 por 30 passos: "26" no 30º passo vivo (36º real com 6 de hitstop); Sangramento 1: "1" e resto 0,2; toggle desligado: nenhum número e dano igual
- [x] AC-ST-20 — último status zera com resto ≥ 1: número final; inimigo que morre: nenhum
- [x] AC-ST-23 — `estado(inimigo)` nos passos 99/100/340 do AC-ST-02 e Abalo 29/0 do AC-ST-10

---

## Implementation Notes

- Evento `EvNumeroDeStatus(inimigo_id, valor)` (subclasse de `EventoDoPasso`, só ids e valores).
- O teto de 3 sinais e a redução em multidão são da vista (ADR-0011 §8); aqui só a consulta que a alimenta.

---

## Out of Scope

- Desenho dos sinais e do número: épicos `production/epics/feedback-de-combate/` e `production/epics/pipeline-visual/`

---

## Files

- src/gameplay/status/modulo_de_status.gd
- src/gameplay/status/vista_de_status.gd
- tests/unit/status/status_numero_e_consulta_test.gd

Fatia: `game_hud.gd`/`world_view.gd` não mostram status; adaptação fica com os épicos de Apresentação.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status/status_numero_consulta_e_tuning_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/efeitos-de-status/story-002-tick-e-dano-silencioso.md`; épico `production/epics/orquestrador-do-passo/` (`EventosDoPasso`)
- Unlocks: stories de sinais/números em `production/epics/feedback-de-combate/` e `production/epics/pipeline-visual/`
