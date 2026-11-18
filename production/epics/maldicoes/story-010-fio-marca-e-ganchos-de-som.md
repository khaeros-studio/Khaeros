# Story 010: Fio de vínculo, marca do Virote, leitura da Maldição e ganchos `sfx_maldicao_*`

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature (vista na Apresentação)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (§ Visual/Audio Requirements ML-V1–ML-V5, ML-A1; § UI Requirements, indicador de atraído)
**Requirement**: `TR-maldicoes-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0016: Áudio: ganchos e vozes
**ADR Decision Summary**: Três famílias de shader, material por entidade, relógios `t_vivo`/`t_apres`; a Apresentação só lê o estado e a lista de eventos (ADR-0011). Eventos → sons pela lista do passo, `SomDef` do catálogo, pool de vozes (ADR-0016).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0011: linhas de `CanvasItem` sem feather no 4.7 — o fio não pode ser `draw_line`/`Line2D` sem textura; ADR-0016 MEDIUM.

**Control Manifest Rules (Presentation)**:
- Required: vista guiada por `t_vivo`/`t_apres`; todo `CanvasItem` de mundo com shader de uma das famílias; sons por eventos
- Forbidden: `draw_line`/`draw_arc`/`Line2D` sem textura para traço de jogo; `world_view.gd` com `_draw()` como pipeline; vista chamar `play()`
- Guardrail: draw calls dentro da fatia de entidades (200) e VFX (64)

---

## Acceptance Criteria

*From GDD `design/gdd/maldicoes.md` § Visual/Audio Requirements (sem AC numerado; verificação manual):*

- [x] ML-V1: Maldição em Tinta `#0D0E14` e ardósia com amarras em Osso; nunca Magenta `#E0259C` exposto em repouso.
- [x] ML-V2: fio curvo em Osso translúcido (2 px) sempre visível do peito do Iniciado à Maldição em campo; tensiona reto tracejado com `d_jog > 408 px`; ao estourar (> 480 px) pulsa em Osso claro.
- [x] ML-V3 e ML-V4: marca do Virote como ilhós de Osso nos pés do único inimigo marcado; nenhum golpe da Maldição usa o passe de telégrafo de chão.
- [x] ML-V5 e indicador de atraído: flash em Osso por 4 passos ao ser atingida; Exaustão dissolve em tinta pelo fio em 12 passos; inimigo atraído com traço vertical em Osso acima da cabeça.
- [x] ML-A1: ganchos `sfx_maldicao_ataque`, `_chamado_salto`, `_chamado_pouso`, `_troca_tecnica`, `_exausta`, `_pronta`, `_recusa` disparados pelos eventos, no máximo 1 por gancho por passo.

---

## Implementation Notes

- A vista lê `posicao_e_raio`, `estado_pacto` e a lista de eventos; nunca escreve no módulo.
- Fio como malha/quad texturizado na família de shader de mundo; material duplicado por entidade.
- Os streams vêm de `SomDef`; o mapeamento evento → som fica na tabela do épico `audio`.

---

## Out of Scope

- Smears e chute de câmera do pouso e da técnica: épico `production/epics/feedback-de-combate/`.
- Bloco do Pacto: épico `production/epics/hud/`.

---

## Files

- `src/presentation/maldicoes/maldicao_view.gd`, `fio_de_vinculo_view.gd`, `marca_virote_view.gd`
- `assets/shaders/<família de mundo>/fio_de_vinculo.gdshader`
- `production/qa/evidence/maldicoes-fio-e-marca-evidence.md` + screenshots

Código da fatia: `src/presentation/world_view.gd` não ganha desenho de Maldição (o ADR-0011 proíbe o `_draw()` como pipeline; substituído pelo épico `pipeline-visual`).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidos em `production/qa/evidence/` (fio normal, tensionado, estourado; marca; atraído) + sign-off em `production/qa/evidence/maldicoes-fio-e-marca-evidence.md`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-009-camara-leitura-eventos-e-orcamento.md`; épicos `production/epics/pipeline-visual/`, `production/epics/audio/`
- Unlocks: None
