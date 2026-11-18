# Story 005: Ordem de crédito com Run e Portas (morte vence a limpeza)

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R4, F3, Edge Cases)
**Requirement**: `TR-economia-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4.3, §4.6); ADR-0002: Canal de eventos
**ADR Decision Summary**: Portas creditam `porta` ao processar `camara_limpa` só se `run.ativa()` (morte vence a limpeza); na vitória a Run lê `coletados_run()` antes de `bonus = creditar(VITORIA, fragmentos_vitoria)` e guarda o efetivo no `ResumoDaRun`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0002)
**Engine Notes**: Nenhuma API nova; ordem garantida pela cadeia de chamadas síncronas, não por ordem de registro de ouvintes.

**Control Manifest Rules (Feature)**:
- Required: Portas consultam `run.ativa()` antes de conceder
- Required: `ResumoDaRun` sem setters
- Forbidden: a Run gravar disco

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md`, scoped to this story:*

- [x] AC-EF-22 (com `camaras_jogaveis = 7`, emenda Pactos): saldo 11; portas pagam 2 e 3; a Run lê coletados 5, `bonus` 15; saldo 31; resumo coletados 5, bônus 15, total 20.
- [x] AC-EF-23 / AC-EF-28: morte no índice 2 após porta de 2 → saldo 13, total 2, sem bônus; `jogador_morreu` e `camara_limpa` no mesmo passo → Portas não creditam.
- [x] AC-EF-24: porta de Fragmentos com `p` 3 credita 3; bênção sem pool credita como `porta` com o `p` da câmara.
- [x] AC-EF-25 (só com o Limiar de 7 câmaras; ver AC-EF-35 na story 006): extremos 22 / 15 / 0 / 7 recalculados para o índice 5 recompensado.

---

## Implementation Notes

*Derived from ADR-0015 §4:*

- A Economia não muda: o teste monta Run, Portas e conta reais (ou dublês das duas pontas) e verifica a ordem.
- Decisão do GDD: com Run R3-P o índice 5 é câmara comum recompensada (Chefes F6 emendado); valores de AC-EF-22/25 seguem a coluna "Índice 5 recompensado" da F3-P.

---

## Out of Scope

- Story 006: crédito do chefe
- Épico portas-e-recompensas: a fórmula `2 + floor(p/3)` (dono: `RewardTable`)

---

## Files

- `tests/integration/economia/ordem_com_run_e_portas_test.gd`

Código atual da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/economia/ordem_com_run_e_portas_test.gd`
**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/economia-de-fragmentos/story-003-gastar-nova-run-exportar.md`, `production/epics/economia-de-fragmentos/story-004-leitura-nula-e-composicao.md`; `production/epics/portas-e-recompensas/EPIC.md` e `production/epics/run-e-regioes/EPIC.md` (stories a criar)
- Unlocks: `production/epics/economia-de-fragmentos/story-006-credito-do-chefe.md`

## Completion Notes

**2026-11-16 (gameplay-programmer).** Teste `tests/integration/economia/ordem_com_run_e_portas_test.gd` (5 casos, passou): vitória 31 / resumo 5+15=20; morte no índice 2 → 13 e total 2; morte e `camara_limpa` no mesmo passo não creditam; porta p 3 = 3 e bênção sem pool como `porta`; extremos com índice 5 recompensado (25/15/0/10, sem chefe).

Pendência: Run e Portas são dublês que seguem o contrato do ADR-0015 §3/§4 (épicos run-e-regioes e portas-e-recompensas sem código). Trocar pelos módulos reais quando existirem; a Economia não muda.
