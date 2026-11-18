# Story 010: Run completa com sistemas reais, leitura de fixture e pior passo (5 linhas em 3 ms)

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R4, R11, F2, F3, F3-P, F4)
**Requirement**: `TR-telemetria-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP; ADR-0002: Canal de eventos
**ADR Decision Summary**: Gravação síncrona no passo com descarga por linha (sem thread nem fila); o pior passo (morte, 5 linhas) cabe em 3 ms; custo medido pelo relógio injetado. Telemetria primeira na entrega da lista.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM / HIGH (ADR-0002)
**Engine Notes**: A medição real exige o `ArmazemUserGodot` e o EX-0013 (P1/P4/P5) concluído; `user://_testes/<caso>/` como raiz.

**Control Manifest Rules (Presentation)**:
- Required: Telemetria é `ConsumidorDeEventos` puro
- Forbidden: thread ou fila de gravação (ADR-0013, alternativa rejeitada)
- Guardrail: 1 ms por linha e 3 ms por passo (TL2)

---

## Acceptance Criteria

- [x] AC-TL-27 (F2, R11): a fixture de uma sessão (3 runs) lida pelo leitor de teste calcula `dano_rel` por câmara (ex.: 20/80 = 0,25) sem o jogo.
- [x] AC-TL-28 (R4): run de 6 câmaras no Limiar com Run, Câmaras, Bênçãos, Portas e Combate reais e a fixture "portas livres dão bênção: ofertas nos índices 0, 1, 2 e 4" → 21 linhas de run na ordem da F3 e `run_encerrada` com os 10 campos por nome.
- [x] AC-TL-40 (F3-P): run vencedora de Pactos (7 câmaras) com Chefes e Vínculo reais, fixture "primeira run de Pactos, portas livres dão bênção, pactuar o chefe" → número de linhas da F3-P na ordem esperada; arquivo < 12 KB para a run.
- [x] TR-telemetria-012: o pior passo (5 linhas) fica dentro de 3 ms no build real, medido com o relógio do adaptador.

---

## Implementation Notes

- Testes de integração com raiz `user://_testes/telemetria/<caso>/`; leitor de teste da story 005.

---

## Out of Scope

- —

---

## Files

- `tests/integration/telemetria/run_completa_test.gd`, `run_pactos_completa_test.gd`, `pior_passo_test.gd`
- `tests/fixtures/telemetria/sessao_3_runs.jsonl`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/telemetria/run_completa_test.gd`, `run_pactos_completa_test.gd`, `pior_passo_test.gd`
**Status**: [x] Complete — `tests/unit/telemetria/run_completa_e_pior_passo_test.gd`

---

## Dependencies

- Depends on: stories 004, 005, 007, 008, 009 deste épico; épicos `production/epics/run-e-regioes/`, `production/epics/chefes/`, `production/epics/vinculo-e-pactos/` (story 009), `production/epics/experimentos-de-engine/` (EX-0013)
- Unlocks: None
