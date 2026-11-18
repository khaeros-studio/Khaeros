# Story 003: Seguimento com lookahead (F2/F3) e interpolação sobre o passo fixo

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera
**ADR Decision Summary**: No render, `P = lerp(P_anterior, P_atual, f_i)`; atualiza-se `pos_seguir` por F4/F3 com alvo P; converte-se o cursor, calcula-se `m = cursor_mundo − P` e o lookahead F2; `pos` por F2 → F4 → F3. O par anterior/atual avança a cada passo de física, inclusive no hitstop.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Ativar `physics/common/physics_interpolation`; nós de câmera e parallax em `physics_interpolation_mode = OFF` (já recebem resultado calculado); não atribuir P interpolado manualmente a um sprite que a engine também interpola. Suavidade a 144 Hz só se prova por gravação manual.

**Control Manifest Rules (this layer)**:
- Required: um único escritor de canvas, sem dupla interpolação; `passo_congelado()` faz só anterior=atual e a Cena usa esse histórico (ADR-0007, ADR-0008)
- Forbidden: ler `Time`/`OS`; o relógio da câmera é `t_apres` injetado (ADR-0001)
- Guardrail: F3 independe da fatia de Δt (duas fatias de 0,05 = uma de 0,10)

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-19** F2: P (1000, 600), mouse m = (300, 400), R_mouse 480 → (1072, 696); m = (60, 80) → (1015, 620); mira (0,0) → P; em 360 direções e distâncias 0–2000 px, |alvo − P| ≤ 120 e nunca diminui com a distância; Redução de movimento e mira automática → P; analógico direito com `intensidade_mira` 0,4 → lookahead 48 px, com 0,5 direto → 60 px
- [ ] **AC-20** Duas câmeras com a mesma `pos_seguir` e lookahead diferente → direção da mira idêntica (ver clarificação do ADR sobre o vetor que gera o lookahead)
- [ ] **AC-21** F3 com h = 0,12, de 0 para 100: Δt 0,10 → 43,9; 0,12 → 50; 0,24 → 75; 1 → 99,69; duas fatias de 0,05 = uma de 0,10 (1e-6); para Δt de 0,001 a 5 nunca passa de 100
- [ ] **AC-34** P_anterior (0,0), P_atual (10,0), f_i 0,25 → P (2,5; 0); num teleporte P_anterior = P_atual no mesmo quadro
- [ ] **AC-35** (Integration) Câmara 2880×1080, Redução de movimento ligada, jogador a 300 px/s, física a 60 Hz e render a 144 Hz: no último 0,5 s de 1 s o avanço de `pos` por quadro varia menos de 1% entre quadros consecutivos e não encosta no limite da F4
- [ ] **AC-38** (Integration) Com `physics/common/physics_interpolation` ligado, o nó da câmera tem `physics_interpolation_mode` = `OFF`; **[M]** em monitor de 144 Hz, Investida e corrida em linha reta numa câmara de 2880 andam sem degraus de 60 Hz, com gravação a 144 quadros/s retida em `production/qa/evidence/`

---

## Implementation Notes

*Derived from ADR-0007 §3 e §6:*

F3 e idades F5 usam `t_apres` injetado; o orquestrador é o único dono do teto `dt_max_apres` e da contagem do relógio; a câmera não aplica outro relógio nem usa delta bruto. Analógico usa a direção e a intensidade da última amostra; mira automática e Redução de movimento produzem lookahead zero. Hitstop deixa a apresentação correr; o par anterior/atual repetido evita oscilação. Na pausa entre renders preservar a pose corrente e ressincronizar o histórico sem salto (verificar com sprites reais). A mira de gameplay usa `pos`; só o cálculo do lookahead usa `pos_seguir`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: impulsos
- Story 006: estados (Pausa, Bênção, Morte, Transição, Corte)
- Story 008: o compositor que aplica o resultado

---

## Files

- `src/foundation/cena/camera_de_apresentacao.gd`
- `src/foundation/cena/entrada_camera.gd`, `src/foundation/cena/estado_visual_camera.gd`
- `tests/unit/cena/lookahead_e_suavizacao_test.gd`
- `tests/integration/cena/camera_a_144hz_test.gd`
- `production/qa/evidence/cena-camera-144hz.<ext>` (gravação [M])

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/lookahead_e_suavizacao_test.gd` — must exist and pass; gravação a 144 Hz retida para o AC-38 manual

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-002-limites-da-camara-e-camera-tuning.md`; `production/epics/orquestrador-do-passo/` (stories ainda por criar: `t_apres` injetado)
- Unlocks: `production/epics/cena-e-camera/story-005-impulsos-de-camera.md`, `production/epics/cena-e-camera/story-006-estados-corte-e-relogio-da-camera.md`

## Completion Notes

**Arquivos**: `src/foundation/cena/camera_de_apresentacao.gd` (`atualizar_quadro`, `interpolar`, `alvo_f2`, `intensidade_mouse`, `suavizar_f3`), `src/foundation/cena/entrada_camera.gd` e `src/foundation/cena/estado_visual_camera.gd`; `tests/unit/cena/lookahead_e_suavizacao_test.gd` (11 casos, passam); `tests/integration/cena/camera_a_144hz_test.gd` (1 caso, passa).

- AC-19, AC-20, AC-21 e AC-34 cobertos. Ordem no render: P interpolado → `pos_seguir` por F4/F3 → cursor convertido com `pos_seguir` → F2 → F4 → F3 em `pos`. Δt é a diferença do `t_apres` injetado e nunca fica negativo; não há `Time` nem delta bruto.
- `Vector2` é float32: as varreduras de F2 usam tolerância 1e-3.
- AC-35: simulação lógica com física a 60 Hz e render a 144 Hz; a variação ficou abaixo de 1 % e a câmera não tocou o limite da F4. Isso não prova fluidez visual (ADR-0007).
- **Pendências**: AC-38. O `physics_interpolation_mode = OFF` vale para o nó `CompositorDeCena` (story 008). A gravação [M] a 144 Hz (`production/qa/evidence/cena-camera-144hz.*`) precisa de execução com janela e monitor de 144 Hz.
- Execução: `godot --headless -s -d ... GdUnitCmdTool.gd -a res://tests/unit/cena -a res://tests/integration/cena --ignoreHeadlessMode` (Godot 4.7.2) → 61 casos no épico, 0 falhas, 0 erros, 0 órfãos, sem erro de parse.
- Pendência comum do épico: `src/app/main.gd` e `src/presentation/world_view.gd` ainda usam `src/presentation/game_camera.gd`, que foi mantido (o orquestrador não autorizou editar esses arquivos). Migrar para `CameraDeApresentacao` e apagar `game_camera.gd` fica para o épico orquestrador-do-passo / story 008.
- Esquema `CameraTuning` duck-typed (lido por `Object.get`): `meia_vida`, `lookahead_max`, `raio_mouse`, `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos`, `presets_impulso` (nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`), `camara_minima`/`camara_maxima`. O épico conteudo deve adotar esses nomes ou avisar.
