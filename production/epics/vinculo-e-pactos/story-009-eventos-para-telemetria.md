# Story 009: Eventos do Vínculo para a Telemetria (estado inicial ampliado, encontro, pacto, fim de run)

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (§ Depended On By — Telemetria); contrato em `design/gdd/telemetria-local.md` R4-P
**Requirement**: `TR-vinculo-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos; ADR-0013: Persistência do MVP
**ADR Decision Summary**: O Vínculo publica `EventoDoPasso` (`EvVinculoGanho`, `EvPactoFormado`, `EvEncontroFalhou` e o resultado do encontro) na lista do passo; a Telemetria é `ConsumidorDeEventos` puro e só lê. O `estado_inicial` da run ganha `dupla` e `pactos`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0002) / MEDIUM (ADR-0013)
**Engine Notes**: —

**Control Manifest Rules (Feature)**:
- Required: quem é de sessão ouve a run por eventos no canal
- Forbidden: o Vínculo conhecer a Telemetria
- Guardrail: —

---

## Acceptance Criteria

*Campos exigidos pelos AC da Telemetria (verificados do lado do emissor; a gravação é do épico telemetria-local):*

- [x] Os eventos carregam os campos de AC-TL-34 (`pactos.especies` com `id`+`nivel`, `encontro_pendente`, `primeiro_encontro_visto`, `runs_pactos_sem_encontro`), AC-TL-36 (índice, espécie, `resultado`, Vida) e AC-TL-38 (`pontos_run`, `vinculo_pontos`, `nivel`, `subiu_nivel` por espécie).
- [x] Ordem (AC-TL-37/38): `pacto(primeiro)` antes de `run_iniciada`; `pacto(encontro)`/`pacto(chefe)` antes de `run_encerrada`; `vinculo_fim_run` depois de `run_encerrada` com o mesmo `run`.
- [x] Run de outra Doutrina não emite encontro, pacto nem fim de vínculo (AC-TL-39).

---

## Implementation Notes

- Classes de evento no catálogo de eventos do ADR-0002; nenhuma chamada direta à Telemetria.

---

## Out of Scope

- Escrita das linhas: `production/epics/telemetria-local/story-009-schema-2-pactos.md`.

---

## Files

- `src/gameplay/vinculo/eventos_vinculo.gd`
- `tests/unit/vinculo/eventos_para_telemetria_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/vinculo/eventos_para_telemetria_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-007-pontos-niveis-e-consolidacao.md`
- Unlocks: `production/epics/telemetria-local/story-009-schema-2-pactos.md`
