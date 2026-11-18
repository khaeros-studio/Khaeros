# Story 006: Estados da câmera, corte atômico e relógio `t_apres`

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-009`, `TR-cena-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera (com ADR-0001 para a troca de câmara)
**ADR Decision Summary**: O corte ocorre no quadro da metade do wipe: nova época, limites e spawn, iguala P_anterior/P_atual, `pos_seguir = F4(P)` e `pos = F4(alvo_F2)`, zera impulsos e publica a transformação; o relógio reinicia depois, por `reiniciar_relogio(epoca, t_apres)`, aceito uma vez por época. Pausa, Bênção, Morte e Transição congelam a câmera.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: `reset_physics_interpolation()` dos nós teleportados no mesmo quadro do corte; sincronização com o zero de `t_vivo`/`t_apres` do orquestrador a conferir na integração.

**Control Manifest Rules (this layer)**:
- Required: as seis ações da troca de câmara rodam uma vez, no mesmo quadro, em ordem fixa; `t_vivo`/`t_apres` zeram na troca (ADR-0001); relógio da câmera é `t_apres` injetado (ADR-0007)
- Forbidden: retomar o seguimento só porque o estado local Corte acabou; F3 no quadro do corte (ADR-0007)
- Guardrail: pedido de corte repetido na mesma época não teleporta nem corta de novo

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-22** Na troca de câmara: `pos` = alvo preso no mesmo quadro e nenhum impulso ativo; com wipe roteirizado de 2·M quadros, `pos` fica na câmara velha até o quadro M − 1 e está no alvo preso da câmara nova no quadro M, o mesmo do teleporte do jogador
- [ ] **AC-30** Seguindo + troca → Corte: no mesmo quadro `pos` = alvo preso e 0 impulsos, e no seguinte o estado é Seguindo; Seguindo + pausa → Pausa: `pos` constante por 60 quadros, deslocamento 0, zoom 1, e ao despausar sem impulso anterior; Seguindo + chefe entra → Intro de chefe; zoom_intro 1,3 → zoom_total 1,15; zoom_intro 1,10 + pesado em t = 0 → 1,144; zoom_intro 1,15 + pesado → 1,15; com Redução de movimento → 1
- [ ] **AC-30b** Bênção, Morte e Transição: impulsos zerados e câmera parada; impulso enviado nesses estados é descartado; Pausa aberta por cima da Bênção volta a **Bênção**, não a Seguindo, com `pos` constante e 0 impulsos no retorno; a coluna "Sai para" de Seguindo lista Corte, Pausa, Bênção, Morte, Transição e Intro de chefe
- [ ] **AC-39** Câmera com injeção vazia de `CameraTuning`, mira roteirizada e um impulso pesado → por 60 quadros `pos` constante, deslocamento 0, zoom 1 e 0 impulsos; reinjetado o tuning, no quadro seguinte o lookahead volta e a troca de câmara seguinte corta para o alvo preso

---

## Implementation Notes

*Derived from ADR-0007 §6, §7 e Clarificações:*

Na primeira entrada em Pausa, Bênção, Morte ou Transição, limpar impulsos e restaurar deslocamento 0/zoom 1; Pausa sobre Bênção retorna a Bênção. Morte e Transição conservam a câmera parada mesmo com `t_apres` avançando para outros efeitos. O corte visual dura um quadro, mas se o estado global ainda é Transição a nova câmera fica parada até descobrir/voltar a Jogo (Corte → Seguindo de AC-30 é condicionado ao estado global permitir seguir). `reiniciar_relogio` só aceita a época atual e uma vez por corte, sem retroceder o relógio por pedidos repetidos ou antigos. O progresso do wipe é do Pipeline e não reinicia junto. A fonte de mira usada no corte é um valor válido capturado, não exige ações de Input em Transição.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: cálculo dos impulsos
- Épico orquestrador-do-passo: a ordem das seis ações e o zero de `t_vivo`/`t_apres`
- Épico pipeline-visual: progresso do wipe

---

## Files

- `src/foundation/cena/estados_da_camera.gd`
- `src/foundation/cena/camera_de_apresentacao.gd` (`cortar`, `reiniciar_relogio`)
- `src/foundation/cena/corte_de_camera.gd`
- `tests/unit/cena/estados_da_camera_test.gd`
- `tests/unit/cena/corte_e_relogio_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/estados_da_camera_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-003-seguimento-lookahead-e-interpolacao.md`, `production/epics/cena-e-camera/story-005-impulsos-de-camera.md`; `production/epics/orquestrador-do-passo/` (stories ainda por criar: troca de câmara e relógios)
- Unlocks: None

## Completion Notes

**Arquivos**: `src/foundation/cena/estados_da_camera.gd` e `src/foundation/cena/corte_de_camera.gd`; `cortar`, `reiniciar_relogio`, `mudar_estado` e `retomar` em `camera_de_apresentacao.gd`; `tests/unit/cena/estados_da_camera_test.gd` (7 casos, passam); `tests/unit/cena/corte_e_relogio_test.gd` (4 casos, passam).

- AC-22, AC-30, AC-30b e AC-39 cobertos. O corte faz `pos_seguir = F4(P)` e `pos = F4(alvo_F2)` com a mira capturada no `CorteDeCamera`, zera os impulsos e publica o snapshot. Não aplica F3 no quadro do corte e ignora uma época já vista. `reiniciar_relogio` só aceita a época atual, uma vez.
- Decisões que desviam da coluna "Sai para" (registradas em `EstadosDaCamera.SAI_PARA`):
  - Bênção → Pausa: a Pausa abre por cima da Bênção e volta a ela.
  - Corte → Transição: no corte durante o wipe, a câmera nova fica parada até o estado global voltar a Jogo (Clarificação do ADR).
  - Intro de chefe → Pausa/Morte.
  - Morte não sai para nenhum estado.
- **Pendências**: `reset_physics_interpolation()` dos nós teleportados e a sincronia com o zero de `t_vivo`/`t_apres` do orquestrador ficam para a integração (épico orquestrador-do-passo e story 008).
- Execução: `godot --headless -s -d ... GdUnitCmdTool.gd -a res://tests/unit/cena -a res://tests/integration/cena --ignoreHeadlessMode` (Godot 4.7.2) → 61 casos no épico, 0 falhas, 0 erros, 0 órfãos, sem erro de parse.
- Pendência comum do épico: `src/app/main.gd` e `src/presentation/world_view.gd` ainda usam `src/presentation/game_camera.gd`, que foi mantido (o orquestrador não autorizou editar esses arquivos). Migrar para `CameraDeApresentacao` e apagar `game_camera.gd` fica para o épico orquestrador-do-passo / story 008.
- Esquema `CameraTuning` duck-typed (lido por `Object.get`): `meia_vida`, `lookahead_max`, `raio_mouse`, `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos`, `presets_impulso` (nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`), `camara_minima`/`camara_maxima`. O épico conteudo deve adotar esses nomes ou avisar.
