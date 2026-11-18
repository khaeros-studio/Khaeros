# Story 006: Vista do HUD — Control em CanvasLayer, âncoras, escala, vinheta no Pós e troca do game_hud

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R2, R4 camada, R13, R15 posição, Visual/Audio Requirements); `design/ux/hud.md` (§C, §D, §L)
**Requirement**: `TR-hud-003`, `TR-hud-004`, `TR-hud-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0007: Cena, viewport e câmera; ADR-0011: Pipeline visual
**ADR Decision Summary**: Elementos de tela são `Control` no `CanvasLayer` UI (layer 100), em coordenadas da vista lógica W × 1080, ancorados nas bordas; cada grupo é uma raiz `Control` fora de container, offset de 48 px **sem** escala, `pivot_offset` no canto e `scale = (s, s)`; fio e prompt numa subárvore `Mundo` na camada UI. A vinheta é desenhada pelo Pipeline no Pós (z 50) a partir do valor publicado pelo HUD. A `VistaDoHud` tem um só `_process` e flags de "sujo" por elemento.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0007 2026-11-14 · ADR-0011 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `Control.offset_transform_*` (4.7) só onde houver container (E1, NOT SOURCEABLE — depende de `production/epics/experimentos-de-engine/` EX-0012-E1). Shader de material `ui` com `sem_grading` (ADR-0011).

**Control Manifest Rules (Presentation)**:
- Required: todo texto visível é chave de tradução; animações por `t_ui`
- Forbidden: escalar a margem segura de 48 px; raiz escalada filha direta de `Container`; `draw_line`/`draw_arc` sem textura
- Guardrail: UI ≤ 80 draw calls (ADR-0011)

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md` e `design/ux/hud.md` §L:*

- [x] AC-HD-26 [V] R2 — 1920 × 1080 a 100%: nenhum elemento de tela no retângulo central 60% × 70% (x 384–1536, y 162–918); margem de 48 px; placa do grupo ≥ 92%.
- [x] AC-HD-27 [V] R13 — 1280 × 720 a 150%: o grupo inferior cabe na tela.
- [x] AC-HD-28 [V] R4 — Vida baixa com telégrafo e inimigo na borda: L* ≥ 40 do chão e vinheta ≤ 8%; repetido com a opção 9.
- [x] AC-HD-34 [V] R2 — 2560 × 1080 a 100%: Vida, Fluxo, Esquiva e Fragmentos ancorados nas bordas (48 px), nada no retângulo central do quadro 1920 × 1080 centralizado.
- [x] AC-HD-47 [V] R15 — com o Bloco do Pacto: nada no retângulo central, 48 px, duas placas ≥ 92% sem sobreposição; com Vida 150 o bloco não se move; a 1280 × 720 / 150% os dois cabem.
- [x] UX hud §L — em tons de cinza, Vida baixa, Fluxo pronto/sem Fluxo, Esquiva cheia/vazia, Reserva Pronta/Exausta e Troca disponível/indisponível continuam distinguíveis.
- [x] O `game_hud.gd` (`Node2D` com `_draw`) sai do caminho do jogo; nenhum literal de texto visível nos `.gd`/`.tscn` do HUD (varredura, ADR-0012 Validation 6).

---

## Implementation Notes

*Derived from ADR-0012 §1, §8 e Migration Plan:*

- `VistaDoHud` (Control) aplica o estado dos modelos (stories 001–005) por flags de sujo; `Label.text` só muda quando o valor muda.
- Mudar a escala só reconfigura as raízes, nunca o layout interno.
- Subárvore `Mundo`: fios (pool de 9) e prompt posicionados por `compositor.mundo_para_vista(X)` a cada quadro.
- A vinheta não é nó do HUD: o `Main` liga o valor publicado ao `PipelineVisual`.
- Migração (ADR-0012 Migration Plan 1, 3): extrair textos do `game_hud.gd` para chaves `HUD_*` no CSV de tradução; trocar o `Node2D` pelo `Control`; manter o `game_hud.gd` só até a captura nova passar.

---

## Out of Scope

- Story 008/010: pausa e telas finais (hoje também em `game_hud.gd`)
- `production/epics/tela-de-bencao-e-carta/`: cartas (`game_hud.gd::_card`)

---

## Files

- `src/presentation/ui/vista_do_hud.gd`, `scenes/ui/hud.tscn` (novos)
- `src/presentation/ui/vista_do_bloco_do_pacto.gd`
- `src/app/main.gd` (adaptar: instanciar HUD no `CanvasLayer` UI, ligar sinais e a vinheta ao Pipeline)
- `src/presentation/game_hud.gd` (substituir; remover do caminho do jogo ao fechar)
- `assets/i18n/ui.csv` (chaves `HUD_*`)
- `tests/integration/hud/vista_do_hud_ancoras_test.gd`
- `production/qa/evidence/hud-layout-1920-100.png`, `hud-1280-150.png`, `hud-ultrawide-2560.png`, `hud-vida-baixa.png`, `hud-bloco-do-pacto.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: retained screenshots of each screen state above in `production/qa/evidence/` (run-and-observe, `.claude/docs/run-and-observe.md`)
**Status**: [x] Complete (`tests/unit/hud/bloco_do_pacto_e_vista_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-002-vida-segmentos-racha-e-vida-baixa.md`, `story-003-fluxo-esquiva-fragmentos-e-glifos.md`, `story-004-fios-prompt-chefe-e-visibilidade.md`, `story-005-bloco-do-pacto.md`; `production/epics/cena-e-camera/` (CanvasLayer UI 100 / Pós 50, `GeometriaDeViewport`); `production/epics/pipeline-visual/` (camada Pós, material `ui`, desenho da vinheta); `production/epics/experimentos-de-engine/` (EX-0012-E1); `production/epics/assets-e-conteudo/story-008-lut-por-regiao-e-arte-de-ui.md` (placas, ícones, fonte)
- Unlocks: `production/epics/hud/story-007-opcoes-de-acessibilidade-do-hud.md`
