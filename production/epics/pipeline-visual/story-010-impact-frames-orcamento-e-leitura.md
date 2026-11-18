# Story 010: Impact frames vistos, orçamento e memória por captura, acessibilidade e leitura

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Fechamento do épico com GPU: os três impact frames na captura, o teto de passes, a cena de estresse F10 (500 draw calls, overdraw, partículas, luz e memória de textura 512/448 MiB), luz fora do aviso, daltonismo/cinza, paridade D3D12 × Vulkan e HDR, e os quatro testes manuais de leitura com testadores.

**GDD**: `design/gdd/pipeline-visual.md` (R7, R9, R11, F10, Edge)
**Requirement**: `TR-pipeline-007` (vista), `TR-pipeline-008`, `TR-pipeline-009`, `TR-pipeline-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: Orçamento contado sem lote (exceto sombras), proxy em runtime e captura PIX/RenderDoc como fonte de verdade; memória medida com o monitor de textura na cena de estresse e na câmara do chefe; VV13 dispara de propósito e é registrado.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: EX-0011-E1 (monitor de draw calls 2D vs. captura), E2 e E4. NEEDS VERIFICATION: a constante `Performance.RENDER_TEXTURE_MEM_USED` não está na referência. HDR 4.7 existe sem chave de projeto documentada.

**Control Manifest Rules (this layer)**:
- Required: único escritor de globais; passes ocultos com `visible = false`
- Forbidden: Never ler a tela nos passes
- Guardrail: draw calls 500 (ambiente 40, sombras+telégrafos 54, entidades 200, VFX 64, passes 6, UI 80, reserva ≥ 56); overdraw ≤ 3,5 média / ≤ 5 pico; memória de textura 512 MiB, alerta 448

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-39 [V] R7 — impact frame `recusa`
- [x] AC-PV-40 [V] R11 — impact frame `reduzido`
- [x] AC-PV-70 [V] R7 — impact frame `chefe`
- [x] AC-PV-42 [P] R7 — teto dos passes de tela
- [x] AC-PV-48 [P] R9/F10 — cena de estresse (`tests/performance/visual/estresse_f10.tscn`), incluindo memória de textura ≤ 512 MiB com alerta em 448 (ADR-0011 §8)
- [x] AC-PV-73 [V] R9 — a luz não toca o aviso
- [x] AC-PV-51 [V] R11/§4.7 — daltonismo e cinza
- [x] AC-PV-53 [V] Edge/E2 — paridade D3D12 × Vulkan e HDR
- [x] AC-PV-55 [M] P3 — o perigo num relance
- [x] AC-PV-56 [M] R5 — crescimento se lê
- [x] AC-PV-57 [M] R6/R8 — leitura do hitstop
- [x] AC-PV-58 [M] Edge — Steam Deck (1280 × 800)

---

## Implementation Notes

*Derived from ADR-0011 Performance Implications, Validation Criteria and §8:*

- Captura PIX (D3D12) e RenderDoc (Vulkan) por diferença D_g por grupo; o lote do y-sort nunca é contado a favor.
- O proxy de draw calls por grupo (instâncias visíveis) exposto ao Feedback para a degradação (ver feedback story 005).
- [M]: 5 testadores conforme o critério; registrar testador, build e resultado.

---

## Out of Scope

- Lógica do limitador e dos modos (stories 002/003)

---

## Files

- `tests/performance/visual/estresse_f10.tscn`
- `src/presentation/visual/proxy_de_orcamento.gd`
- `production/qa/evidence/pipeline-visual-010-*.png`, capturas `.pix`/`.rdc` referenciadas
- `production/qa/evidence/pipeline-visual-010-evidence.md` (sign-off + resultados [M])

Código da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas em `production/qa/evidence/` + sign-off (art-director para cor e leitura, technical-artist para medida) em `production/qa/evidence/pipeline-visual-010-evidence.md`; capturas de desempenho com limiar
**Status**: [x] Complete (`tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-007-pool-de-telegrafos-24-slots.md`, `production/epics/pipeline-visual/story-008-nos-por-camada-e-validador.md`, `production/epics/pipeline-visual/story-009-traco-do-jogador-e-vfx-das-maldicoes.md`; `production/epics/experimentos-de-engine/EPIC.md` (EX-0011-E1, E2, E4)
- Unlocks: None
