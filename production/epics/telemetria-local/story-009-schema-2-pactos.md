# Story 009: Schema 2 — `run_iniciada` de Pactos, resumo de 12 campos, `encontro_pacto`, `pacto` e `vinculo_fim_run`

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R4-P, emenda Pactos 2026-11-15)
**Requirement**: `TR-telemetria-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP; ADR-0002: Canal de eventos
**ADR Decision Summary**: Schema 2 do `.jsonl` com as linhas de Pactos, alimentadas pelos eventos do Vínculo e da Run na lista do passo; a Telemetria não conhece o Vínculo diretamente.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM / HIGH (ADR-0002)
**Engine Notes**: —

**Control Manifest Rules (Presentation)**:
- Required: Telemetria é `ConsumidorDeEventos` puro
- Forbidden: escrever no jogo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-34: run de Pactos (`vulto_mudo`, `espreitador_da_fenda`) → `estado_inicial.dupla` nessa ordem e `pactos` com `especies` (`id`+`nivel`), `encontro_pendente`, `primeiro_encontro_visto`, `runs_pactos_sem_encontro`; Lâmina → `dupla` vazia e `pactos` `null`; linha 0 com `schema` 2.
- [x] AC-TL-35: vitória com `desfecho_chefe = pactuado` traz os 12 campos da Run R7-P; morte traz `desfecho_chefe = nenhum`.
- [x] AC-TL-36: evento com índice 1, `espreitador_da_fenda`, `pactuada`, Vida 37 → `encontro_pacto` com esses 4 campos; `resultado` fora da lista sai como está e conta `TL3` uma vez.
- [x] AC-TL-37: 1ª run de Pactos → `pacto(primeiro, run 0)` antes de `run_iniciada`; `pacto(encontro)` e `pacto(chefe)` antes de `run_encerrada`; com a Telemetria Armada, `pacto(primeiro)` não é gravado e nada falha.
- [x] AC-TL-38: depois de `run_encerrada`, com o mesmo `run`, uma `vinculo_fim_run` por espécie (ex.: 19 → 50, nível 1 → 3, `subiu_nivel` verdadeiro); Nova run no mesmo passo: `run_encerrada`, `vinculo_fim_run`, `run_iniciada`.
- [x] AC-TL-39: run de Ressonância não grava `encontro_pacto`, `pacto` nem `vinculo_fim_run`.

---

## Implementation Notes

- Atualiza `schema` da linha 0 de 1 para 2 (AC-TL-01 da story 001 passa a esperar 2).

---

## Out of Scope

- Emissão dos eventos: `production/epics/vinculo-e-pactos/story-009-eventos-para-telemetria.md`.

---

## Files

- `src/presentation/telemetria/linhas_de_pactos.gd`, `linhas_de_run.gd`
- `tests/unit/telemetria/schema_2_pactos_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/schema_2_pactos_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/schema_2_pactos_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-006-linhas-de-run-seed-e-impressao.md`; `production/epics/vinculo-e-pactos/story-009-eventos-para-telemetria.md`
- Unlocks: `production/epics/telemetria-local/story-010-run-completa-e-pior-passo.md`
