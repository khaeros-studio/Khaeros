# Story 005: Impulsos de câmera (F5) com remetente único

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera (com ADR-0002 para a entrega no fim do passo)
**ADR Decision Summary**: Só o Feedback envia `preset`, `escala`, `dir`, época e tempo de início no relógio de apresentação; `receber_impulso` rejeita épocas diferentes da atual; máximo de 16 impulsos; em cada render descarta d < 0,05 e soma F5 com ruído cosmético injetável; o vetor final é limitado a 40 depois do Tremor de câmera.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: O Feedback entrega os impulsos ao fim do passo de física, antes da avaliação da câmera no render seguinte; aplicar VFX tarde não pode atrasar o impulso por um quadro adicional.

**Control Manifest Rules (this layer)**:
- Required: `receber_impulso` só do Feedback e rejeita época diferente da atual; todo teste de impulso usa ruído fixo injetado (ADR-0007)
- Forbidden: a câmera decidir hitstop ou consumir RNG estrutural (ADR-0007, ADR-0005)
- Guardrail: no máximo 16 impulsos; o mais antigo sai

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-23** Pesado em t 0,1, dir (1,0), s_t 0,5, ruído (0,5; −1) → (6, −2), módulo 6,32
- [ ] **AC-24** Dois de chefe em t 0, ruído 0 → módulo 40 na direção (1,0) e zoom 1,15
- [ ] **AC-25** Chefe em t 0,6 → zoom 1,025; rm = 1 → zoom 1; s_t = 0 → deslocamento 0 e zoom 1,025
- [ ] **AC-26** Leve ativo em t 0,21 (d = 0,054) e descartado em t 0,22 (d = 0,047); 17 impulsos enviados → 16 ativos e o primeiro saiu
- [ ] **AC-27** s_t 0,25 → exatamente 1/4 do deslocamento de s_t 1, abaixo do teto
- [ ] **AC-28** (Integration) Pesado durante hitstop roteirizado (contador de passos, `Engine.time_scale` = 1) e `t_apres` avançando 0,1 s → d = 0,5, com o jogo parado
- [ ] **AC-29** (Integration) Impulso ativo → pausa → deslocamento 0, zoom 1, `pos` constante; ao despausar o impulso não volta; impulso enviado durante a pausa → descartado
- [ ] **AC-31** (Visual/Feel, **[M]**) O lead assina os presets leve, pesado e chefe (placeholders), com screenshot do quadro de pico em `production/qa/evidence/`
- [ ] Pedido inválido (escala negativa ou não finita, tempo futuro, direção não unitária nem zero) é rejeitado com diagnóstico sem corromper o estado

---

## Implementation Notes

*Derived from ADR-0007 §8:*

Escala multiplica Ak, As e Z. Zoom total é `min(1.15, zoom_intro * zoom_impulsos)`. Redução de movimento força zoom 1 e lookahead 0; Tremor 0 zera chute e tremor preservando o zoom quando a Redução está desligada. Em Pausa, Bênção, Morte e Transição os impulsos são limpos e os recebidos descartados (a máquina de estados fica na story 006). A câmera não tem relógio próprio: idades usam `t_apres` injetado.

**Código atual da fatia:** o tratamento de impulsos de `game_camera.gd` é **adaptar**: reescrever conforme F5, o teto de 16, a rejeição por época e o ruído injetável; remover o uso de `delta` bruto.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: estados e corte
- Épico feedback-de-combate: quem envia os impulsos e os presets finais

---

## Files

- `src/foundation/cena/impulsos_de_camera.gd`
- `src/foundation/cena/pedido_impulso.gd`
- `tests/unit/cena/impulsos_test.gd`
- `tests/integration/cena/impulso_hitstop_pausa_test.gd`
- `production/qa/evidence/cena-impulsos-presets-evidence.md` e capturas

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/impulsos_test.gd` — must exist and pass; o AC-31 manual exige screenshot retido e assinatura do lead

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-003-seguimento-lookahead-e-interpolacao.md`
- Unlocks: `production/epics/cena-e-camera/story-006-estados-corte-e-relogio-da-camera.md`

## Completion Notes

**Arquivos**: `src/foundation/cena/impulsos_de_camera.gd` e `src/foundation/cena/pedido_impulso.gd`; `receber_impulso` em `camera_de_apresentacao.gd`; `tests/unit/cena/impulsos_test.gd` (7 casos, passam); `tests/integration/cena/impulso_hitstop_pausa_test.gd` (2 casos, passam).

- Cobertos: AC-23 a AC-29 e os pedidos inválidos (escala negativa, NaN ou INF; tempo futuro; direção não unitária; outra época; preset desconhecido). A rejeição não altera o estado.
- Ruído cosmético: `Callable(indice) -> Vector2` injetado. Sem ruído injetado, o tremor vale zero. O gerador real (RNG cosmético) tem de ficar em `src/presentation/` (ADR-0005). O delta bruto e o `RandomNumberGenerator` de `game_camera.gd` não foram levados.
- Zoom: `min(teto_zoom, 1 + Σ Z·d)` nos impulsos e `min(teto_zoom, zoom_intro × zoom)` na câmera. Redução de movimento força 1; Tremor 0 preserva o zoom.
- **Pendências**: AC-31 [M], screenshots do quadro de pico dos presets e assinatura do lead. `production/qa/evidence/cena-impulsos-presets-evidence.md` não foi criado: precisa de execução com janela. O Feedback como remetente único fica no épico feedback-de-combate.
- Execução: `godot --headless -s -d ... GdUnitCmdTool.gd -a res://tests/unit/cena -a res://tests/integration/cena --ignoreHeadlessMode` (Godot 4.7.2) → 61 casos no épico, 0 falhas, 0 erros, 0 órfãos, sem erro de parse.
- Pendência comum do épico: `src/app/main.gd` e `src/presentation/world_view.gd` ainda usam `src/presentation/game_camera.gd`, que foi mantido (o orquestrador não autorizou editar esses arquivos). Migrar para `CameraDeApresentacao` e apagar `game_camera.gd` fica para o épico orquestrador-do-passo / story 008.
- Esquema `CameraTuning` duck-typed (lido por `Object.get`): `meia_vida`, `lookahead_max`, `raio_mouse`, `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos`, `presets_impulso` (nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`), `camara_minima`/`camara_maxima`. O épico conteudo deve adotar esses nomes ou avisar.
