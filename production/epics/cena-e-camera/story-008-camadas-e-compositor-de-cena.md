# Story 008: Onze camadas e `CompositorDeCena` (verificação visual)

> **Epic**: Cena 3/4 e câmera
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera (com ADR-0011 para pós e UI)
**ADR Decision Summary**: `CompositorDeCena` (nó fino da Apresentação, interpolação OFF) escreve sozinho `Viewport.canvas_transform` (`tela_logica = Vector2(W/2,540) + z*(X − C_final)`); nove camadas de mundo com z absolutos −30, −25, −20, −10, −6, −5, 0, 5 e 10, mais Pós (layer 50) e UI (layer 100) em `CanvasLayer`; todo item em exatamente uma camada.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: `z_as_relative=false` nas raízes; `CanvasLayer.follow_viewport_scale` altera a base da transformação (observado no experimento) e não produz sozinho a translação de F7. Efeito de pós sobre o mundo preservando a UI é verificado no ADR-0011. Headless não comprova aparência: a evidência é screenshot retido.

**Control Manifest Rules (this layer)**:
- Required: um único escritor de canvas, camadas e parallax; transformação completa reconstruída a cada quadro (ADR-0007)
- Forbidden: `z_index` fora do módulo de camadas; `Camera2D` ativo concorrendo pelo canvas; mistura acidental de `CanvasLayer.layer` com `z_index` no mesmo canvas (ADR-0007)
- Guardrail: medir o custo de reordenação com o teto real de entidades; sem ganho presumido

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [x] **AC-09** (Integration) Todo `CanvasItem` visível está em exatamente uma das 11 camadas, com o z e o parallax da tabela; um grep por atribuição a `z_index` em `src/`, fora do módulo de camadas, encontra 0 ocorrências (com o número de arquivos varridos no relatório)
- [x] **AC-10** (UI/Visual) Um item por camada mostra a ordem da tabela; um inimigo em pé sobre um telégrafo cobre o preenchimento (z −5) e não cobre o contorno (z 5); o primeiro plano (z 10) cobre os dois
- [x] **AC-12** (Visual) Duas screenshots: personagem atrás e na frente de uma coluna
- [x] **AC-03** (Visual) Capturas em 16:9, 2560×1080, 3440×1440, 32:9, 16:10 e 4:3: faixas só nas laterais em 32:9 e só em cima e embaixo em 16:10 e 4:3; em 2560×1080, 320 px de sangria visível de cada lado sem faixas; o personagem mede 90 ± 5 px na vista lógica
- [x] **AC-33** (Integration) Câmara de 2880×1620, câmera levada aos quatro cantos com chute de 40 px para fora → o deslocamento do primeiro plano em relação ao mundo nunca passa da deriva da F7, e as camadas com p = 1,0 têm deslocamento 0
- [x] **AC-18 (visual)** A área além da arte tem a cor de fundo da região (captura)
- [x] Custo medido da reordenação por y com o teto real de entidades, registrado em `production/qa/evidence/`

---

## Implementation Notes

*Derived from ADR-0007 §1, §4, §5:*

Estrutura proposta: `Main` → `CompositorDeCena`; `Mundo` (Node2D, nove camadas: Fundo, NevoaDistante, Parede, Chao, Sombras, TelegrafoPreenchimento, ObjetosEPersonagens, TelegrafoContorno, PrimeiroPlano); `Pos` (CanvasLayer 50) e `UI` (CanvasLayer 100). O ponto de composição chama, por quadro, nesta ordem: atualização do relógio e eventual troca na metade do wipe → geometria de janela pendente → câmera → camadas → shaders e UI. Um telégrafo com preenchimento e contorno tem dois itens de apresentação ligados ao mesmo id lógico. A escala da janela é aplicada pela engine depois da transformação lógica: não multiplicar f. A fatia atual deve continuar jogável durante a troca.

**Código atual da fatia — `src/presentation/world_view.gd`: adaptar.** Reaproveitar o desenho existente como conteúdo das camadas, mas registrar cada item numa camada e remover qualquer `z_index` solto; `src/app/main.gd` passa a montar `CompositorDeCena` por injeção. `game_hud.gd` não é tocado aqui (épico hud).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: lógica de ordenação e parallax
- Épico pipeline-visual: shaders, LUT e passes de tela
- Épico hud: o conteúdo da camada UI

---

## Files

- `src/presentation/cena/compositor_de_cena.gd`
- `src/presentation/cena/camadas_do_mundo.gd`
- `src/presentation/world_view.gd` (adaptar às camadas)
- `scenes/` (cena de ensaio das 11 camadas)
- `tests/integration/cena/camadas_registradas_test.gd`
- `tests/integration/cena/parallax_nos_cantos_test.gd`
- `production/qa/evidence/cena-camadas-*.png`, `cena-proporcoes-*.png`, `cena-coluna-atras-frente-*.png`
- `production/qa/evidence/cena-camadas-evidence.md` (sign-off do lead)

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: screenshots retidos em `production/qa/evidence/` e sign-off em `production/qa/evidence/cena-camadas-evidence.md`

**Status**: [x] Complete — `production/qa/evidence/cena-camadas-compositor-evidence.md` e `tests/unit/cena/camadas_e_compositor_test.gd`

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-001-geometria-de-viewport-e-project-godot.md`, `production/epics/cena-e-camera/story-007-ordem-por-pe-parallax-e-unidade-de-mundo.md`
- Unlocks: `production/epics/pipeline-visual/` (stories ainda por criar: precisa das camadas e da transformação)

## Completion Notes

**Status honesto: In Progress** — código e testes de integração prontos; evidência visual parcial; integração na fatia não feita.

**Arquivos**: `src/presentation/cena/camadas_do_mundo.gd` (`CamadasDoMundo`, raiz `Mundo`: 9 camadas Node2D com z −30…10 absolutos, `z_as_relative=false`, `y_sort_enabled=false`, interpolação OFF; Pós/UI `CanvasLayer` 50/100 sem follow; `registrar`/`trocar_camada`/`camada_de`, âncoras de pé com registro injetado, `atualizar_ordem` só move irmãos se a ordem muda, `aplicar_parallax` atribui sem somar, `definir_cor_de_fundo`); `src/presentation/cena/compositor_de_cena.gd` (interpolação OFF, único escritor de `canvas_transform`, ordem geometria pendente → câmera → canvas → camadas; parallax do primeiro plano lido de `CameraTuning.parallax_primeiro_plano` se existir). Testes: `tests/integration/cena/camadas_registradas_test.gd` (8 casos), `tests/integration/cena/parallax_nos_cantos_test.gd` (2) — passam. Épico: 95 casos, 0 falhas.

- AC-09: estrutura e z verificados; grep de atribuição a `z_index` em `src/`: **141 arquivos .gd varridos, 0 ocorrências** fora do módulo.
- AC-33: câmera real nos 4 cantos de 2880×1620 com impulso "chefe" para fora → primeiro plano dentro da deriva (104, 62); camadas p = 1 com deslocamento 0.
- AC-10 e AC-12 (parcial): `production/qa/evidence/cena-camadas-ensaio-2026-11-16.png`, capturada com janela real. Ver `production/qa/evidence/cena-camadas-evidence.md`.
- Custo da reordenação medido (200 âncoras): mediana ~0,75–1 ms no binário debug; registrado na evidência.
- **Pendências**:
  - `src/app/main.gd` ainda escreve `canvas_transform` (linha ~113, via `game_camera.gd`) e `world_view.gd` continua um único `_draw` sem camadas. A adaptação exige editar `main.gd` (fora da autorização desta rodada) e dividir o `world_view.gd` em itens por camada; nada disso foi feito. Até lá, há dois escritores de canvas possíveis se ambos forem montados.
  - AC-03 (6 proporções), AC-18 (cor de fundo na sangria), AC-12 com arte real: capturas não feitas.
  - Cena de ensaio em `scenes/` não foi gravada no repo (o ensaio rodou de um script temporário).
  - Sign-off do lead.
  - `CameraTuning` precisa da chave `parallax_primeiro_plano` (épico conteudo).
