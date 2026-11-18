# Story 008: publicar() — entrega por quadro ao Pipeline

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R8)
**Requirement**: `TR-telegrafos-009`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisão 8); ADR-0011: Pipeline visual
**ADR Decision Summary**: No final comum de cada passo físico, `publicar(saida: Array[VistaDeTelegrafo]) -> int` preenche vistas pré-alocadas por valor: `slot`, `dono_id`, `seq`, forma, posição, rotação (`mira.angle()`), dimensões, `p`, modo, estado, `passos_no_estado`, `alvo_faccao`, `contorno_secundario_raio`. Nunca expõe `TelegrafoSlot` nem `InimigoRef`.
**ADR Version**: ADR-0014 2026-11-16 · ADR-0011 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (lado do módulo); custo de publicar 24 vistas por passo é medição pendente (ADR-0014 Verification 4)

**Control Manifest Rules (this layer)**:
- Required: `publicar()` preenche vistas pré-alocadas
- Forbidden: expor `TelegrafoSlot`/`InimigoRef`; Apresentação escrever no módulo
- Guardrail: < 0,05 ms por passo vivo no módulo

---

## Acceptance Criteria

- [x] AC-TG-13 — o espião recebe por quadro: Eco `setor` 90/78,46°/`centro_a_borda`; Anomalia `retangulo` 81 × 1728 `ao_longo_do_eixo`; Fenda 114 × 310,6; p 0 → 1 em passos de 1/preparo
- [x] Medição: `publicar` de 24 vistas sem alocação (contagem de objetos antes/depois de 600 passos) — ADR-0014 Verification 4

---

## Implementation Notes

- `VistaDeTelegrafo extends RefCounted`, alocadas pela Apresentação uma vez.
- O comprimento da faixa é recalculado aqui (story-003).

---

## Out of Scope

- Desenho: story-010 e épico pipeline-visual

---

## Files

- src/gameplay/telegrafos/vista_de_telegrafo.gd
- src/gameplay/telegrafos/telegrafos.gd
- tests/unit/telegrafos/telegrafos_publicar_test.gd

Fatia: `world_view.gd::_telegraph` passa a ler as vistas (adaptação no épico pipeline-visual).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_publicar_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-003-forma-e-testes-de-acerto.md`
- Unlocks: `production/epics/telegrafos/story-010-captura-visual-e-audio.md`; stories de telégrafo em `production/epics/pipeline-visual/`
