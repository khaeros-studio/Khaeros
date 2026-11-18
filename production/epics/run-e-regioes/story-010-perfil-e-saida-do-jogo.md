# Story 010: Gravação do perfil no fim da run e saída do jogo

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R8-P; R2 última arma)
**Requirement**: `TR-run-016`, `TR-run-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§7); ADR-0013: Persistência do MVP
**ADR Decision Summary**: o `GravadorDePerfil` só marca `pendente`; o `Main`, depois de `passo_fisico()`, chama `sessao.gravar_se_pendente(estado)`, que grava fora de `JOGO`/`INICIANDO`. No fim da run: `vinculo.consolidar_run()` direto → `EvRunEncerrada` → pendente → grava no fim desse passo. Sair do jogo com run ativa = abandono completo + gravação síncrona + `quit()`. A run nunca é salva; registro de pactos e vínculo ficam no perfil.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: MEDIUM
**Engine Notes**: **verificação pendente** (ADR-0015): `get_tree().set_auto_accept_quit(false)` + `NOTIFICATION_WM_CLOSE_REQUEST` no `Main` em 4.7.2/Windows — a gravação roda antes de `get_tree().quit()`. ADR-0013: `ConfigFile`/`FileAccess` em `user://`, gravação atômica com `.bak`.

**Control Manifest Rules (this layer)**:
- Required: gravação do perfil só em `gravar_se_pendente` (estado ≠ JOGO) ou em `sair_do_jogo()` (ADR-0015, ADR-0013)
- Forbidden: a Run gravar disco; saldo de Fragmentos no `perfil.cfg`

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md` e ADR-0015 Validation Criteria, scoped to this story:*

- [x] **AC-RN-36 (persistência)** Depois de `nova_run`, o registro de pactos (`soberano_do_limiar`) continua no perfil; a Run não chamou nada que o apague.
- [x] A última arma confirmada é gravada em `PreferenciasDeArma` e volta marcada na próxima sessão (TR-run-012).
- [x] Nenhuma gravação com estado `JOGO` (armazém em memória registra o estado de cada escrita); fim da run grava no fim do mesmo passo.
- [x] `sair_do_jogo()` com run de Pactos ativa → `EvRunEncerrada(abandono)`, consolidação V20b e gravação, nessa ordem.

---

## Implementation Notes

*Derived from ADR-0015 §7:*

- Testes com armazém em memória (`ArmazemDeArquivos` dublê) e `PerfilNulo`; a verificação do `WM_CLOSE_REQUEST` é manual em build Windows e registrada em `production/qa/evidence/`.

---

## Out of Scope

- Épico `persistencia`: repositório, formato e `.bak`.

---

## Files

- `src/gameplay/sessao_de_jogo.gd` (`gravar_se_pendente`, `sair_do_jogo`)
- `src/app/main.gd` (**adaptar**: `set_auto_accept_quit(false)`, `WM_CLOSE_REQUEST`)
- `tests/integration/run/run_perfil_e_saida_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/run/run_perfil_e_saida_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-005-composicao-e-escopo-da-run.md`; épicos `production/epics/persistencia/EPIC.md`, `production/epics/vinculo-e-pactos/EPIC.md` (`consolidar_run`)
- Unlocks: `production/epics/run-e-regioes/story-009-telas-de-inicio-pausa-e-final.md`

**Código da fatia**: não há save; `main.gd` — **adaptar** (fechamento de janela).
