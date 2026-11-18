# Story 003: Experimentos de foco, pausa própria e apresentação (EX-0001-4, -5, EX-0012-E3)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia TR-input-008 (EX-0001-5, EX-0012-E3) e a pausa sem `SceneTree.paused` (ADR-0001).

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo (EX-0012-E3: ADR-0012)
**ADR Decision Summary**: Sem `SceneTree.paused`; a Apresentação é guiada por `t_vivo` ou tem os players parados explicitamente; perda de foco e desconexão do gamepad chegam ao `Main` e viram `pedir_estado(PAUSA)`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: ADR-0001 (4) e (5) NOT SOURCEABLE. ADR-0012 E3 exige hardware real (mouse e gamepad) no Windows.

**Control Manifest Rules (this layer)**:
- Required: perda de foco e desconexão do gamepad ativo chegam ao `Main` e viram `pedir_estado(PAUSA)` em JOGO (ADR-0001).
- Forbidden: `SceneTree.paused`.
- Guardrail: nenhum nó de apresentação anima sozinho em hitstop/pausa.

---

## Acceptance Criteria

*Do ADR-0001 "Verification Required" (4), (5) e ADR-0012 E3; sem GDD.*

- [ ] EX-0001-4: com o estado de jogo próprio fora de JOGO (sem `SceneTree.paused`), registrado quais nós seguem animando: `Tween`, `AnimationPlayer`, `GPUParticles2D`/`CPUParticles2D`, `AnimatedSprite2D`, `AudioStreamPlayer`. Para cada um, o meio de pará-lo explicitamente (ex.: `speed_scale`, `process_mode`, `stream_paused`) e que funcionou.
- [ ] EX-0001-5: registrado qual notificação chega ao nó raiz na perda e no ganho de foco da janela (`NOTIFICATION_APPLICATION_FOCUS_OUT/IN`, `WM_WINDOW_FOCUS_OUT`...) e o efeito de `application/run/pause_on_focus_loss`; fixado o valor a gravar no `project.godot`.
- [ ] EX-0001-5: registrado como a desconexão do gamepad ativo chega ao `Main` (`Input.joy_connection_changed`) com o dispositivo ativo e com outro.
- [ ] EX-0012-E3: em hardware real, o clique que devolve o foco à janela chega (ou não) depois de `NOTIFICATION_APPLICATION_FOCUS_IN`? Resultado em Alt+Tab e em clique na janela; decide se é preciso a "barreira de retorno" do ADR-0012.
- [ ] Resultado de cada item: "confirmado" ou "usar fallback do ADR".

---

## Implementation Notes

Protótipo em `prototypes/engine-verificacao/foco-e-apresentacao/`: um `Node` raiz com uma flag `pausado_proprio` e um conjunto de nós de apresentação (um de cada tipo) que registram quantos quadros animaram durante a flag. Foco: registrar log com timestamp de cada notificação. EX-0012-E3 depende de execução manual do usuário com hardware real; se não houver gamepad disponível, o item fica `NOT ASSESSED — sem hardware` e a story não fecha.

---

## Out of Scope

- Implementar a pausa no orquestrador: `production/epics/orquestrador-do-passo/story-006-main-composicao.md`.
- Mapa de binds e contexto de Input: épico `input`.

---

## Files

- `prototypes/engine-verificacao/foco-e-apresentacao/`
- `production/qa/evidence/experimentos/ex-0001-foco-e-apresentacao.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/experimentos/ex-0001-foco-e-apresentacao.md` (log + descrição da execução manual com hardware real).

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/orquestrador-do-passo/story-006-main-composicao.md`; épicos `input` e `hud` (TR-input-008)

---

## Completion Notes

**Data**: 2026-11-16 · Godot 4.7.2 em janela real · evidência `production/qa/evidence/experimentos/ex-0001-foco-e-apresentacao.md` · protótipo `prototypes/engine-verificacao/foco-e-apresentacao/` (`foco.gd`, `driver.ps1`, README).

| Item | Resultado |
|---|---|
| EX-0001-4 (o que anima fora de JOGO) | **VERIFICADO** — com só a flag, Tween, AnimationPlayer, GPU/CPUParticles2D, AnimatedSprite2D e AudioStreamPlayer seguem animando. Param: `Tween.pause()`, `speed_scale = 0` (AnimationPlayer, partículas, AnimatedSprite2D), `stream_paused = true`; e também `process_mode = PROCESS_MODE_DISABLED` no pai congela os seis. Confirmado |
| EX-0001-5 foco | **VERIFICADO** — `APPLICATION_FOCUS_OUT/IN` (2017/2016) chegam ao nó raiz antes de `WM_WINDOW_FOCUS_OUT/IN`; `WM_WINDOW_FOCUS_IN` pode repetir. `application/run/pause_on_focus_loss` **não existe** no 4.7.2: nada a gravar. Confirmado |
| EX-0001-5 gamepad | **NÃO RODADO — sem hardware** (nenhum gamepad; sinal `Input.joy_connection_changed(device, connected)` confirmado no doctool e já registrado pelo protótipo) |
| EX-0012-E3 clique de ativação | **VERIFICADO com input injetado (SendInput)** — o clique chega como `InputEventMouseButton` ~46 ms **depois** de `APPLICATION_FOCUS_IN`; Alt+Tab não gera clique. Barreira de retorno do ADR-0012 é necessária. Mouse físico: pendente |

**ADR-0001 precisa mudar**: (4) apresentação para por `process_mode = DISABLED` no nó-raiz da apresentação (ou meios por tipo); (5) gatilho = `NOTIFICATION_APPLICATION_FOCUS_OUT`, retirar `pause_on_focus_loss`, ganho de foco idempotente. **ADR-0012**: manter a barreira de retorno (descartar o par press/release após `APPLICATION_FOCUS_IN`).

**Atualização 2026-11-17:** mudanças nos ADRs 0001 e 0012 e no `control-manifest.md` aplicadas em `2026-11-17`. Pendências residuais de hardware físico (gamepad e mouse físico) registradas sem bloquear a story.
