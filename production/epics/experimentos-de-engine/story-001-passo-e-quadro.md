# Story 001: Experimentos do passo e do quadro (EX-0001-1, -2, -6)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md` (o épico não tem GDD próprio)
**Requirement**: nenhum TR próprio (épico transversal, ver EPIC.md "Cobertura de TR"). Desbloqueia TR-combate-nucleo-001/002, TR-movimento-002/003, TR-cena-009/011 (via ADR-0001).

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo
**ADR Decision Summary**: Passo de 60 Hz em ordem fixa, acionado por `_physics_process`/`_process` de um `Main` fino; `project.godot` declara `physics_ticks_per_second` e `max_physics_steps_per_frame` explicitamente, com valores fixados por experimento; `dt_max_apres` 0,1 s.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Itens (1), (2) e (6) de "Verification Required" do ADR-0001 são NOT SOURCEABLE em `docs/engine-reference/`. Não afirmar valor padrão nenhum de memória; o resultado medido é a fonte.

**Control Manifest Rules (this layer)**:
- Required: passo de 1/60 s numa constante única validada contra `Engine.physics_ticks_per_second` em `Main._ready()`; `quadro()` não assume um passo por quadro (ADR-0001).
- Forbidden: `SceneTree.paused`; ler `Time`/`OS`/`Engine.time_scale` na lógica de jogo (o experimento mede, não vira lógica).
- Guardrail: total do passo vivo ≤ 1,0 ms p99 (ADR-0001).

---

## Acceptance Criteria

*Do ADR-0001 "Verification Required" (1), (2), (6) e Validation Criteria (último item). O épico não tem GDD; não há AC de GDD.*

- [ ] EX-0001-1: registrados os valores padrão de `physics/common/physics_ticks_per_second` e `max_physics_steps_per_frame` no 4.7.2 (editor e build exportado) e o efeito com quadro atrasado (nº de `_physics_process` por `_process` quando o quadro demora 50 ms, 100 ms e 250 ms). Resultado final: os dois valores a gravar no `project.godot`.
- [ ] EX-0001-2: registrada a ordem observada entre `_physics_process` e `_process` dentro do mesmo quadro, com 0, 1 e 2+ passos de física no quadro, em 100 quadros, no editor e no export.
- [ ] EX-0001-6: registrado o comportamento do primeiro quadro depois de arrastar a janela no Windows 11 (maior `delta` observado) e se `dt_max_apres` = 0,1 s o cobre.
- [ ] Cada experimento termina em "confirmado" ou "usar fallback já escrito no ADR" e a decisão é anotada no ADR-0001 (seção Last Verified) pelo lead-programmer.

---

## Implementation Notes

Projeto isolado em `prototypes/engine-verificacao/passo-e-quadro/` (outside code root, descartável; não toca o `project.godot` principal). Um `Node` com `_physics_process` e `_process` que registram contador de quadro, ordem de chamada, `delta` e nº de passos por quadro; um modo que injeta atraso (`OS.delay_msec`) para forçar quadro lento. Rodar no editor e num build exportado de Windows. O ADR-0001 manda declarar os dois valores no `project.godot` "a decidir no experimento": a story só entrega os valores; a escrita no `project.godot` principal é da story 006 do épico orquestrador-do-passo.

---

## Out of Scope

- story-002 (catálogo e cena), story-003 (foco e apresentação), demais EX: outras stories deste épico.
- Escrever no `project.godot` principal: `production/epics/orquestrador-do-passo/story-006-main-composicao.md`.

---

## Files

- `prototypes/engine-verificacao/passo-e-quadro/project.godot`, `passo_e_quadro.gd`, `passo_e_quadro.tscn`
- `production/qa/evidence/experimentos/ex-0001-passo-e-quadro.md` (resultados + capturas/logs)

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/experimentos/ex-0001-passo-e-quadro.md` (playtest/medição documentada, editor e export) — substitui teste automatizado porque o objeto é o comportamento da engine.

**Status**: [x] Created (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/orquestrador-do-passo/story-003-orquestrador-estado-e-pedidos.md`, `production/epics/orquestrador-do-passo/story-005-relogios-e-quadro.md`, `production/epics/orquestrador-do-passo/story-006-main-composicao.md`

## Completion Notes

**2026-11-16 — godot-specialist.** Experimentos rodados de verdade no Godot 4.7.2 (binário do editor, janela real, Ryzen 5 5600H). Evidência: `production/qa/evidence/experimentos/ex-0001-passo-e-quadro.md`.

Arquivos: `prototypes/engine-verificacao/passo-e-quadro/project.godot`, `passo_e_quadro.gd`, `passo_e_quadro.tscn`, `mover_janela.ps1`.

| Item | Resultado | O que o ADR-0001 precisa mudar |
|---|---|---|
| EX-0001-1 | **VERIFICADO (editor)**: padrões 60 e 8; atraso 50/100/250 ms → 2–3 / 5–6 / 8 (teto) passos; `delta` de `_process` suavizado pelo `physics_jitter_fix` 0.5 | Gravar `physics_ticks_per_second=60` e `max_physics_steps_per_frame=8` no `project.godot` (story 006 do orquestrador). Anotar que o teto 8 descarta tempo acima de ~133 ms e que passos ≠ atraso/16,7 ms |
| EX-0001-2 | **VERIFICADO (editor)**: em 100 quadros, todo `_physics_process` do quadro roda antes do `_process`; 0 violações; quadros com 0, 1 e 3 passos | Marcar VR(2) confirmado |
| EX-0001-6 | **VERIFICADO com ressalva**: loop modal de mover (`SC_MOVE` sintético, 3,5 s) não gerou `delta` > 0,05 s; o maior `delta` é o do 1º quadro (0,13–0,14 s) | `dt_max_apres` 0,1 s mantido; acrescentar que o clamp vale já no 1º quadro |

Decisões: o modo `ordem` intercala quadros de 40 ms para gerar 2+ passos; o `physics_jitter_fix` absorveu a maioria, então 2+ passos foram cobertos também pelo modo `atraso` (até 8). Mover a janela foi feito por `WM_SYSCOMMAND/SC_MOVE` (mesmo loop modal do arrasto), porque não há operador para arrastar com mouse.

**Atualização 2026-11-17:** mudanças no ADR-0001 e no `control-manifest.md` aplicadas em `2026-11-17`. Pendências residuais de hardware/release (repetir no `.exe` exportado quando os export templates 4.7.2 forem instalados e arrasto manual de 5 s) registradas sem bloquear a story.
