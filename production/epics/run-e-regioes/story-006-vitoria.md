# Story 006: Vitória — câmara do chefe, crédito e run_encerrada

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R4, R4-P)
**Requirement**: `TR-run-004`, `TR-run-015`, `TR-run-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4 passos 5–6); ADR-0002; ADR-0001
**ADR Decision Summary**: ao processar `camara_limpa` com `i == camaras_jogaveis − 1`: lê `conta.coletados_run()` (já com os 6 do chefe) → `bonus = conta.creditar(VITORIA, fragmentos_vitoria)` → monta `ResumoDaRun` → `ENCERRADA(VITORIA)` → `EvRunEncerrada` → pede `MENU` (sem Transição). Em Pactos, `chefe_subjugado` liga `chefe_subjugado_pendente` e a run segue Ativa até `chefe_escolhido` + `camara_limpa(4, chefe)`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: risco herdado do ADR-0001/0002 (ordem do passo e canal); `EvRunEncerrada` tipado com `tipo()` de `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: a Run chama `vinculo.consolidar_run()` direto antes de emitir `EvRunEncerrada` (ADR-0015 §7)
- Required: a Run só troca o estado por `pedir_estado`
- Forbidden: a Run guardar números das Maldições

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story (Fixture RN-P, 7 câmaras):*

- [x] **AC-RN-31** Limpar o índice 5: estado Ativa, a recompensa da porta escolhida depois do 4 é concedida (Fragmentos: 3) e abre 1 porta `chefe`, sem consumir o fluxo `portas`.
- [x] **AC-RN-32** Lâmina, saldo 11, coletados 5; o dublê de Chefes credita 6 e emite `camara_limpa(4, chefe)` no índice 6: 0 portas, 0 `recompensa`, coletados 11, credita 15, `run_encerrada(vitória)` 1 vez, saldo 32, resumo coletados 11, bônus 15, total 26, `desfecho_chefe = abatido`, câmaras limpas 7.
- [x] **AC-RN-33** Pactos: `chefe_subjugado` → run Ativa, sem `run_encerrada`; `chefe_escolhido(soberano_do_limiar, pactuar)` + `camara_limpa(4, chefe)` sem crédito → vitória, bônus 15, `desfecho_chefe = pactuado`; com `exorcizar` e crédito 6: `exorcizado` e coletados soma 6.
- [x] **AC-RN-08 / AC-RN-10** Santuário no índice 3 não encerra a run; na última, a ordem é `camara_limpa`, `fim_da_run`, crédito da vitória, `run_encerrada`; nenhum `pedir_oferta`, `recompensa` nem `bencao_escolhida`; nenhuma Transição. (AC-RN-09/25 valem com a `RegionDef` de 6.)

---

## Implementation Notes

*Derived from ADR-0015 §4–§7:*

- `Run.ao_camara_limpa(p, tipo)` só quando `ativa()` e `i == camaras_jogaveis − 1`.
- `desfecho_chefe` vem de `chefe_escolhido` (só aceito na câmara 6) ou `abatido` quando sem escolha.

---

## Out of Scope

- Story 007: morte e abandono.
- Story 008: o `ResumoDaRun` em si.
- Épico `chefes` story 008/009: crédito do chefe e `limpar_camara_chefe`.

---

## Files

- `src/gameplay/run/run.gd`
- `src/gameplay/run/eventos_da_run.gd` (`EvRunEncerrada`, `EvFimDaRun`)
- `tests/integration/run/run_vitoria_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/run/run_vitoria_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-005-composicao-e-escopo-da-run.md`, `production/epics/run-e-regioes/story-008-resumo-da-run.md`, `production/epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md`, `production/epics/portas-e-recompensas/story-007-escolha-da-porta.md`
- Unlocks: `production/epics/chefes/story-009-subjugado-e-escolha.md` (integração real; antes disso, dublê)

**Código da fatia**: a vitória da fatia (fim das três ondas) é **substituída**.
