# Story 008: Experimentos de UI: offset, ações nativas, textos, clipboard (EX-0012-E1, E2, E4, E5, E6, CB)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia TR-hud-*, TR-tela-bencao-* e TR-input-* (AC-36); EX-0012-CB atende TR-rng-012.

**ADR Governing Implementation**: ADR-0012: UI e HUD
**ADR Decision Summary**: `Control` em `CanvasLayer`, foco duplo, escala 85–150%; esvaziar só as ações nativas `ui_*` citadas e manter `ui_text_*`; AccessKit fora do MVP.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `offset_transform_*` (4.6/4.7), plurais/contexto em CSV (4.6), nome da propriedade de desativação recursiva (4.5), propriedades AccessKit além de `accessibility_live`: NOT SOURCEABLE. E4 e E5 são não bloqueantes.

**Control Manifest Rules (this layer)**:
- Required: `Input`/`InputEvent` só na fronteira de input; eventos identificados por classe.
- Forbidden: `_unhandled_input` por nó para ações de jogo.
- Guardrail: escala de UI 85–150% sem quebra de layout.

---

## Acceptance Criteria

*Do ADR-0012 "Riscos" E1–E3 e do EPIC.md (E4–E6, CB).*

- [ ] E1: `offset_transform_*` altera ou não `get_global_transform_with_canvas()` e o retângulo de acerto (clique) de um `Control`; resultado com 3 valores de offset, em captura.
- [ ] E2: esvaziar as ações nativas `ui_*` citadas no ADR-0012 não quebra `LineEdit` (`ui_text_*` seguem funcionando): digitar, mover cursor, apagar, selecionar (Input AC-36).
- [ ] E4 (não bloqueante): nome da propriedade de desativação recursiva de foco/entrada confirmado no 4.7.2, ou `NOT SOURCEABLE` mantido por escrito.
- [ ] E5 (não bloqueante): propriedades de AccessKit além de `accessibility_live` listadas e usadas, ou mantido "fora do MVP".
- [ ] E6: plurais e contexto de tradução em CSV (4.6) funcionam com `tr_n()`/contexto em pt-BR e en; se não, fallback registrado.
- [ ] CB: `PortaDaAreaDeTransferencia` (clipboard): `DisplayServer.clipboard_set/get` copia e lê a seed (texto hex) no Windows 11, build exportado.
- [ ] Screenshot retido de E1 e E2 em `production/qa/evidence/experimentos/`.

---

## Implementation Notes

Protótipo em `prototypes/engine-verificacao/ui/`. E2: usar `InputMap.action_erase_events` somente nas ações citadas e testar um `LineEdit` com teclado real. CB: a porta é uma abstração (`PortaDaAreaDeTransferencia`) para teste; aqui se verifica só a API real. Resultados que não confirmarem viram o fallback do ADR-0012.

---

## Out of Scope

- HUD e telas de produção: épicos `hud`, `tela-de-bencao-e-carta`.
- E3 (foco por clique): `story-003-foco-e-apresentacao.md`.

---

## Files

- `prototypes/engine-verificacao/ui/`
- `production/qa/evidence/experimentos/ex-0012-ui.md` (+ capturas `.png`)

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: capturas retidas de E1 e E2 + `production/qa/evidence/experimentos/ex-0012-ui.md`.

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: épicos `input` (AC-36), `hud`, `tela-de-bencao-e-carta`

---

## Completion Notes

**Data**: 2026-11-16 · Godot 4.7.2 em janela real + `.pck` exportado (binário do editor; templates de release não instalados) · evidência `production/qa/evidence/experimentos/ex-0012-ui.md` + capturas `ex-0012-e1-c0..c3_*.png`, `ex-0012-e2-selecao.png`, `ex-0012-e2-final.png` · protótipo `prototypes/engine-verificacao/ui/`.

| Item | Resultado |
|---|---|
| E1 | **VERIFICADO** — existe `offset_transform_visual_only` (padrão true): com true, `get_global_transform_with_canvas()`, `get_global_rect()` e o acerto ficam no slot de layout (o clique no slot vazio acerta o botão deslocado); com false, transformação e acerto acompanham o visual. 4 casos em captura |
| E2 | **VERIFICADO** — ações `ui_accept/select/cancel/up/down/left/right/focus_next/prev` esvaziadas; `LineEdit` digita, move caret, apaga, seleciona (Shift+End, Ctrl+A), Enter emite `text_submitted`; Tab não navega. Eventos via `Input.parse_input_event` (teclado físico não usado) |
| E4 | **VERIFICADO (nomes)** — `focus_behavior_recursive` / `mouse_behavior_recursive` (enums `*_BEHAVIOR_INHERITED/DISABLED/ENABLED`) |
| E5 | Listadas `accessibility_name/description/live/controls_nodes/described_by_nodes/labeled_by_nodes/flow_to_nodes`; **não usadas**, mantido fora do MVP |
| E6 | **VERIFICADO** — CSV `keys,?context,?plural,en,pt_BR` com linhas de continuação de `keys` vazio; `tr_n` e `tr(msg, ctx)` corretos em en e pt_BR (pt_BR: 0 é singular), também no `.pck` |
| CB | **VERIFICADO** — `DisplayServer.clipboard_set/get` com a seed hex na janela e no `.pck`; o SO (`Get-Clipboard`) lê o valor. Binário de release: NÃO RODADO |

**ADR-0012 precisa mudar**: registrar `offset_transform_visual_only = true` e que o anel de foco não usa `get_global_transform_with_canvas()`; E2/E4/E6 deixam de ser NOT SOURCEABLE (nomes e formato acima); TR-rng-012 pode usar `DisplayServer.clipboard_*`.
