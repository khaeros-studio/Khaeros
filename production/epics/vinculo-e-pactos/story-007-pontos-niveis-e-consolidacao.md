# Story 007: Pontos e níveis (F3), consolidação no fim da run, abandono e bônus de nível (F4)

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (F. Pontos e níveis; V17, V19, V20, V20b; F3, F4)
**Requirement**: `TR-vinculo-012`, `TR-vinculo-013`, `TR-vinculo-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição; ADR-0013: Persistência do MVP; ADR-0009: Atributos e modificadores; ADR-0017: Aliados e invocações (§12)
**ADR Decision Summary**: `pontos_run` só em memória, com tetos. No fim da run, a Run chama `vinculo.consolidar_run(motivo, venceu)` direto, emite `EvRunEncerrada`, o Gravador marca pendente e grava no fim do passo (estado MORTE/MENU). Sair no meio consolida como abandono com a regra de derrota e o encontro `Aguardando` vira pendente. Bônus de nível entram uma vez na criação da run pela fonte `vinculo:<curse_id>` (`vida_max`), com `mult_recuperacao` e `bonus_dano_basico` guardados na `MaldicaoRef`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW / MEDIUM (ADR-0013)
**Engine Notes**: Arredondamento determinístico do ADR-0009.

**Control Manifest Rules (Feature)**:
- Required: ordem no fim da run (consolidar → `EvRunEncerrada` → gravar); `ResumoDaRun` sem setters
- Forbidden: gravar em estado JOGO
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-16 (V17, F3): espécie da dupla que numa vitória acertou em 6 câmaras, fez 15 abates e 7 técnicas → `pontos_run = 12 + 12 + 6 + 8 = 38`.
- [x] AC-VP-17 (F3): `vinculo_pontos = 19`, nível 1, run soma 31 → `vinculo_pontos = 50`, `nivel = 3`.
- [x] AC-VP-18 (V20): run de Pactos com `pontos_run = 15` para o *Vulto* e morte → 15 somados, `runs_pactos_iniciadas += 1`, Save grava no gatilho "Fim da run".
- [x] AC-VP-19 (V20b): `pontos_run = 9` e encontro `Aguardando`, sair pelo menu → `escrever()` já traz os 9 somados (sem `pts_vitoria`) e `encontro_pendente = [especie]`.
- [x] AC-VP-20 (F4): `baluarte_de_cinza` nível 5 → `vida_max = 142`, Exaustão de 540 passos, básico `13,23` (`12,6 × 1,05`); Chamado, Efeitos (Saída 5, Entrada 7) e recarga da troca iguais à base.

---

## Implementation Notes

- Contagem de câmaras com acerto, abates e técnicas via eventos da lista (`EvMaldicaoGolpe`, abates com `autor_player_id`, `EvTecnicaCombinada`).
- Emite `vinculo_atualizado` antes da tela final.

---

## Out of Scope

- Painel de vínculo na tela final: story 010. Linha `vinculo_fim_run` da telemetria: story 009.

---

## Files

- `src/gameplay/vinculo/pontos_de_vinculo.gd`, `vinculo.gd` (`consolidar_run`)
- `tests/unit/vinculo/pontos_niveis_e_consolidacao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/vinculo/pontos_niveis_e_consolidacao_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-006-consentimento-portas-e-dupla.md`; épicos `production/epics/run-e-regioes/` (fim da run), `production/epics/modificadores/`
- Unlocks: `production/epics/vinculo-e-pactos/story-008-chefe-pactuar-ou-exorcizar.md`, `production/epics/vinculo-e-pactos/story-009-eventos-para-telemetria.md`
