# Story 008: Menu de pausa — Continuar, Abandonar run e seed copiável

> **Epic**: HUD (telas fora do combate: pausa; escolhido por ser o épico de UI de sessão mais próximo — a spec `design/ux/pausa-e-opcoes.md` cita o HUD R12/R13)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` R6 (pausa e abandono); `design/gdd/hud.md` R12 (HUD a 60% sob a pausa); UX: `design/ux/pausa-e-opcoes.md` §1–§10, §14
**Requirement**: `TR-hud-007` (relógio de UI que para com a pausa — a pausa usa `t_real`), `TR-hud-005` (visibilidade pelo estado de jogo). Requisitos de outros épicos implementados aqui como tela: TR-rng-012 (seed na pausa) — o TR continua no épico `rng`; esta story só fornece a superfície.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 3, 4, 7, 11); ADR-0006: Input por passo
**ADR Decision Summary**: `MenuDePausa` (modelo + vista) abre em `JOGO` e `BENCAO`; em `BENCAO` "Abandonar run" fica desabilitado por forma e texto; confirmar chama `PortaDaRun.abandonar()`; "Continuar" chama `retomar()` do orquestrador. Seed vem pronta de `LeituraDaRun.texto_seed()`; "Copiar seed" chama `PortaDaAreaDeTransferencia.copiar(texto)`. Perda de foco da janela em `JOGO` pede `PAUSA`; barreira de retorno ao recuperar o foco.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine Notes**: `DisplayServer.clipboard_set` — **NEEDS VERIFICATION** (não está em `docs/engine-reference/godot/`); conferir na 4.7.2 antes de implementar a porta real. E3 (clique de ativação da janela) depende de `production/epics/experimentos-de-engine/` EX-0012.
**Engine**: Godot 4.7.2 | **Risk**: HIGH

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; todo `Control` interativo com `mouse_filter = MOUSE_FILTER_IGNORE`
- Forbidden: `Button` nativo com foco da engine; `pressed` ligado a ação; `SceneTree.paused`
- Guardrail: animação da pausa por `t_real`

---

## Acceptance Criteria

*From `design/ux/pausa-e-opcoes.md` §14 (spec In Review) e Run R6:*

- [x] Esc em `JOGO` abre a pausa em ≤ 1 passo; em hitstop o aperto é descartado.
- [x] Pausa aberta na Bênção: "Abandonar run" riscado com motivo; Continuar volta à mesma oferta com trava de 300 ms.
- [x] Abandonar exige confirmação com Cancelar em foco; confirmado, a run termina com motivo `abandono` e o saldo de Fragmentos não muda.
- [x] A seed aparece no formato `XXXX-XXXX · vX.Y.Z · cXXXX`; Copiar seed põe esse texto na área de transferência (porta falsa no teste; real verificada à mão).
- [x] Perder o foco da janela em `JOGO` pausa; o clique que devolve o foco não aciona Continuar nem Abandonar.
- [x] Todo o fluxo é concluído só com gamepad.

---

## Implementation Notes

*Derived from ADR-0012 §3, §4, §7, §11:*

- `ModeloDoMenuDePausa` com `ModeloDeFoco` (story `production/epics/tela-de-bencao-e-carta/story-001-modelo-de-foco-dados-da-carta-e-fileira.md`); itens desabilitados com motivo (padrão P11 de `design/ux/interaction-patterns.md`).
- HUD esmaecido a 60% (story 004 já expõe a opacidade por estado).
- Chaves `PAUSA_*`, `PAUSA_COPIAR_SEED`, `SEED_COPIADA`.

---

## Out of Scope

- Story 009: submenu Opções
- Épico `run-e-regioes`: `PortaDaRun.abandonar()` e o motivo `abandono`

---

## Files

- `src/presentation/ui/menu_de_pausa.gd`, `vista_do_menu_de_pausa.gd`, `scenes/ui/pausa.tscn` (novos)
- `src/presentation/ui/porta_da_area_de_transferencia.gd` (novo)
- `src/app/main.gd` (adaptar: ligar pausa/retomar); `src/presentation/game_hud.gd` (remover a tela de pausa desenhada à mão)
- `tests/unit/hud/menu_de_pausa_test.gd`
- `production/qa/evidence/pausa-jogo.png`, `pausa-bencao.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshots `production/qa/evidence/pausa-jogo.png` e `pausa-bencao.png`; teste do modelo em `tests/unit/hud/menu_de_pausa_test.gd` (recomendado)
**Status**: [x] Complete (`tests/unit/hud/pausa_opcoes_e_fim_de_run_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`; `production/epics/tela-de-bencao-e-carta/story-001-modelo-de-foco-dados-da-carta-e-fileira.md`; `production/epics/orquestrador-do-passo/` (`pedir_estado(PAUSA)`, `retomar()`); `production/epics/input/` (`ComandosDeTela`, barreira de retorno); `production/epics/rng/` (texto da seed F9)
- Unlocks: `production/epics/hud/story-009-tela-de-opcoes.md`
