# Story 010: Evidência visual da arena e das portas; duração da câmara

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (Visual/Audio Requirements, Game Feel)
**Requirement**: `TR-camaras-003` (obstáculos legíveis na vista)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto; ADR-0008: Movimento e colisão própria
**ADR Decision Summary**: A vista das pedras e dos telégrafos sai da mesma geometria da lógica (círculos próprios); a apresentação só lê.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica); render pelo Pipeline visual (ADR-0011, HIGH)
**Engine Notes**: Captura conforme `.claude/docs/run-and-observe.md`.

**Control Manifest Rules (Feature)**:
- Forbidden: a vista guardar geometria própria das pedras

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-25: captura de uma câmara com 4 pedras e 6 inimigos: pedras distintas do chão, sem cobrir o contorno dos telégrafos, sangria esconde a parede; em tons de cinza e nos 3 simuladores de daltonismo.
- [x] AC-CO-26: captura da câmara limpa com 2 e 3 portas abertas: moldura dourada e rachaduras magenta legíveis por forma e valor.
- [x] AC-CO-27 / AC-CO-43 (registro manual, proposta): câmara 0 entre 10 e 25 s e a 4 entre 25 e 60 s com jogador médio; em ≥ 80% das câmaras de encontro, nenhum inimigo fere a acuada nos 2 s depois de nascer.

---

## Implementation Notes

- AC-CO-27/43 são playtest (tipo [M]); registrar testador, build e contagem no arquivo de evidência.

---

## Out of Scope

- Épico pipeline-visual: shaders e LUT

---

## Files

- `src/presentation/world_view.gd` (adaptar: desenhar pedras e portas a partir da câmara)
- `production/qa/evidence/camaras-arena-e-portas-evidence.md` + capturas PNG

Código atual da fatia: `world_view.gd` é **adaptado** (hoje desenha a arena fixa da fatia).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas em `production/qa/evidence/` + sign-off em `production/qa/evidence/camaras-arena-e-portas-evidence.md`
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-008-santuario-e-portas.md`; `production/epics/pipeline-visual/EPIC.md` (story a criar)
- Unlocks: None
