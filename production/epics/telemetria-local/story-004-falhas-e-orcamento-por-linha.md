# Story 004: Falhas absorvidas (TL1, Parada por falha), campo ausente (TL3) e orçamento por linha (TL2)

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R8, F4; § Edge Cases)
**Requirement**: `TR-telemetria-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP
**ADR Decision Summary**: Todo `bool`/erro do escritor é checado; uma falha gera um `TL1` e o estado Parada por falha, sem nova tentativa nem aviso ao jogador. O custo por linha é medido pelo relógio injetado (µs); acima de 1 ms conta `TL2` e a gravação continua.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: `Time.get_ticks_usec()` só no adaptador real do relógio.

**Control Manifest Rules (Presentation)**:
- Required: Telemetria é `ConsumidorDeEventos` puro
- Forbidden: lançar erro para o jogo
- Guardrail: 1 ms por linha, 3 ms por passo

---

## Acceptance Criteria

- [x] AC-TL-18 (R8): escritor que falha ao abrir → um `TL1`, Parada por falha, o jogo continua e nenhum evento posterior lança erro.
- [x] AC-TL-19 (R8): escritor que falha na 10ª linha → para de gravar, sem nova tentativa, sem aviso, sem exceção.
- [x] AC-TL-25 (F4): escritor que demora 4 ms por linha → conta `TL2` e a gravação continua.
- [x] AC-TL-31 (Edge): sem a pasta, ela é criada; se não puder, `TL1`; evento depois de Parada por falha é descartado sem erro.
- [x] AC-TL-24 (Edge): evento com campo faltando → a linha sai com `null` e `TL3` conta uma vez por tipo.

---

## Implementation Notes

- `RelatorDeAvisos` injetado conta TL1–TL3.

---

## Out of Scope

- Orçamento do pior passo com 5 linhas: story 010.

---

## Files

- `src/presentation/telemetria/telemetria.gd`
- `tests/unit/telemetria/falhas_e_orcamento_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/falhas_e_orcamento_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/falhas_e_orcamento_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-001-sessao-arquivo-e-campos-comuns.md`
- Unlocks: `production/epics/telemetria-local/story-010-run-completa-e-pior-passo.md`
