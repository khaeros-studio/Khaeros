# Story 003: Layout de pedras, retângulo jogável e obstáculos

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R2, R5, F4)
**Requirement**: `TR-camaras-003`, `TR-camaras-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico; ADR-0008: Movimento e colisão própria; ADR-0014: Telégrafos: geometria e teto
**ADR Decision Summary**: O fluxo 8 `layout` tem consumo fixo (1 + 3 × 30 = 91 reais: 10 candidatos por pedra, 3 reais cada); obstáculos são círculos próprios e o retângulo jogável é a câmara inteira, entregues a Movimento, Selo, Telégrafos e IA — sem corpos de física.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Sem `CharacterBody2D`/`StaticBody2D` (ADR-0008).

**Control Manifest Rules (Feature)**:
- Required: Movimento é o único escritor da posição
- Forbidden: RNG da engine; corpos de física para pedras

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-03: câmara 1920×1080 prende o jogador (raio 27) a x ∈ [27; 1893] e y ∈ [27; 1053].
- [x] AC-CO-04 / AC-CO-05: com `layout` dublê dando n = 1 (3 pedras) o fluxo consome 91 números; cada pedra fica no 1º candidato com folga ≥ 105 px (104,9 recusado, 105 aceito); sem candidato válido a pedra é omitida e o consumo continua 91.
- [x] AC-CO-06: raio ∈ [42; 79,5] em passos de 1,5; x ∈ [270; 1650]; y ∈ [255; 765]; nenhuma pedra cobre a entrada.
- [x] AC-CO-11 (parte `layout`): posição e Vida do jogador não mudam o estado do fluxo `layout` depois da câmara.

---

## Implementation Notes

- A lista de obstáculos é entregue por referência somente leitura ao Movimento (colisão), Selo, Telégrafos e IA; a câmara é a dona.

---

## Out of Scope

- Story 006: quando o layout é montado
- Story 009: layout fixo do chefe

---

## Files

- `src/gameplay/camaras/layout_da_camara.gd`
- `tests/unit/camaras/layout_de_pedras_test.gd`

Código atual da fatia: `movement.gd` (clamp à arena) é **adaptado** pelo épico movimento-e-esquiva para receber o retângulo e os obstáculos desta story; a fatia não tem pedras.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/layout_de_pedras_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-001-tuning-e-validacao-wv.md`; `production/epics/rng/EPIC.md`; `production/epics/movimento-e-esquiva/EPIC.md` (colisão com círculos — stories a criar)
- Unlocks: `production/epics/camaras-e-ondas/story-005-spawn-e-candidatos.md`, `production/epics/camaras-e-ondas/story-006-montagem-na-transicao.md`
