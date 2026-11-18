# Story 005: CartaView e VistaDaTela — Control, anatomia da carta, foco visível, gravura e acessibilidade

> **Epic**: Tela de bênção e carta
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R2, R4, R5, R10, R11, R14, R15, F5, Visual/Audio Requirements); UX: `design/ux/tela-de-bencao.md`, `design/ux/interaction-patterns.md` (P1, P2, P9)
**Requirement**: `TR-tela-bencao-002`, `TR-tela-bencao-008`, `TR-tela-bencao-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 1, 3, 5, 11); ADR-0011: Pipeline visual; ADR-0013: Persistência do MVP
**ADR Decision Summary**: `CartaView` recebe `DadosDaCarta` e nunca lê `BoonDef`; texto do preço por `tr(preco_chave).format({"valor": v})`. Escala `s` na raiz da fileira; 106% e +12 px do foco por `offset_transform_*` (cartas em `HBoxContainer`); anel de foco desenhado pela vista, stylebox `focus` vazio; `mouse_filter = IGNORE`. Mundo congelado em gravura por `modo_bencao` do Pipeline. Alto contraste troca o tema; redução de movimento troca a entrada por fade ≤ 300 ms e o foco por corte seco; "Reduzir flashes" pelo limitador do ADR-0011. Flags do `RepositorioDeOpcoes`.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0011 2026-11-16 · ADR-0013 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `Control.offset_transform_*` (4.7) e efeito no acerto (E1) — NOT SOURCEABLE; o acerto usa o slot de layout. Depende de EX-0012-E1/E2 (`production/epics/experimentos-de-engine/`).

**Control Manifest Rules (Presentation)**:
- Required: `CartaView` recebe `DadosDaCarta`; teste de acerto pelo slot de layout; todo texto é chave de tradução; sons de UI por `FilaDeSonsDeInterface`
- Forbidden: `Button` nativo com foco da engine; teste de acerto pelo visual com `offset_transform_*`; vista chamar `play()`
- Guardrail: UI ≤ 80 draw calls; uma Tela instanciada uma vez e reaproveitada

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md` e `design/ux/tela-de-bencao.md` §14:*

- [x] AC-TB-21 [L] R2/R4 — `preco_texto` nulo: placa vazia, mesma altura; O Preço com Nome: texto da chave com `{valor}` em posição fixa.
- [x] AC-TB-22 / AC-TB-33 [L] R14 — alto contraste (painéis 100%, raridade por linhas e palavra); redução de movimento (fade ≤ 300 ms, foco 106% em corte seco); "Reduzir flashes" sem flash — três testes separados.
- [x] AC-TB-23 [L] R15 — modo bênção e arma usam topo da Doutrina; modo melhoria topo reto neutro (teste de interface).
- [x] AC-TB-26 [V] R4 — uma carta de cada raridade a 100%: zonas nas porcentagens da Art Bible, dourado só no ícone, topo sem ornamento de raridade.
- [x] AC-TB-27 [V] R11 — em cinza com 3 cartas, a carta em foco (106%, anel) é apontada em < 1 s por 5 de 5 avaliadores.
- [x] AC-TB-28 [V] F1 — 5 cartas (reservado) a 100% e 150%: todas dentro da margem de 48 px, contando a focada a 106%.
- [x] UX §14 — em tons de cinza Comum/Rara/Épica e "tem preço"/"sem preço" distinguíveis; mouse parado sobre a carta 0 ao abrir: foco na do meio, 1º clique só foca.
- [x] TR-tela-bencao-008 — fundo com mundo congelado em gravura e insígnia da Doutrina da arma; entrada ≤ 0,45 s (captura).

---

## Implementation Notes

*Derived from ADR-0012 §3, §5, §11 e Migration Plan:*

- Slots de layout separados do visual; auxiliar que aplica `MOUSE_FILTER_IGNORE` na subárvore.
- `VistaDaTela` emite `preco_revelado` e `tela_fechada` a partir dos instantes do modelo (story 003); o `Main` liga ao HUD, Feedback, Áudio e à `PortaDaBencao.notificar_tela_fechada()`.
- Textos reaplicados em `NOTIFICATION_TRANSLATION_CHANGED`; rótulos com `autowrap_mode` e redução até o piso (Edge Cases do preço e do ganho).
- Chaves `BENCAO_*`.

---

## Out of Scope

- Story 007/008: modos arma e maldicao (conteúdo da carta)
- `production/epics/assets-e-conteudo/story-008-lut-por-regiao-e-arte-de-ui.md`: molduras, ornamentos, ícones e glifos

---

## Files

- `src/presentation/ui/carta_view.gd`, `vista_da_tela.gd`, `scenes/ui/carta_view.tscn`, `scenes/ui/tela_de_bencao.tscn` (novos)
- `src/presentation/game_hud.gd` (remover `_card` e a tela de bênção desenhada à mão); `src/app/main.gd` (adaptar: ligar sinais)
- `tests/unit/tela_bencao/carta_view_dados_test.gd`, `acessibilidade_da_tela_test.gd`
- `tests/integration/tela_bencao/mouse_e_aceitar_mesmo_passo_test.gd` (ADR-0012 Validation 3)
- `production/qa/evidence/tela-bencao-raridades.png`, `tela-bencao-foco-cinza.png`, `tela-bencao-5-cartas-100-150.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshots retidos em `production/qa/evidence/` (AC-TB-26, 27, 28); testes unitários dos [L] acima
**Status**: [x] Complete (`tests/unit/tela_bencao/tuning_carta_view_e_bencaos_real_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-003-troca-confirmacao-e-sinais.md`, `story-004-tela-bencao-tuning-validacao.md`; `production/epics/pipeline-visual/` (`modo_bencao`, limitador de flashes, material `ui`); `production/epics/experimentos-de-engine/` (EX-0012-E1/E2); `production/epics/hud/story-007-opcoes-de-acessibilidade-do-hud.md` (flags de opções)
- Unlocks: `production/epics/tela-de-bencao-e-carta/story-007-modo-arma-escolha-de-arma.md`, `story-008-modo-maldicao-escolha-do-pacto.md`, `story-009-tela-de-consentimento-do-pacto.md`
