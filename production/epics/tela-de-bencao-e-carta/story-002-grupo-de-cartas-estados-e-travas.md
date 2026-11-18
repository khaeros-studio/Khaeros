# Story 002: GrupoDeCartas — 8 estados, travas por borda de subida, pausa e foco da janela

> **Epic**: Tela de bênção e carta
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R7, R10, R12, F3, F4, States and Transitions, Edge Cases)
**Requirement**: `TR-tela-bencao-005`, `TR-tela-bencao-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 4, 5, 6, 7); ADR-0006: Input por passo
**ADR Decision Summary**: `GrupoDeCartas` (RefCounted, sem sinais) é a máquina de 8 estados (Fechada, Entrando, Travada, Livre, Trocando, Confirmando, Saindo, Pausada) com F1–F5, travas por borda de subida depois de `t_abrir` e relógio injetado (`t_ui`). Ao abrir, o roteador troca o contexto para Bênção (esvazia o buffer, exige soltar). Perder o foco da janela em `BENCAO` só limpa entradas, não pausa. A pausa de cima devolve a mesma oferta com trava de 300 ms.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: lógica pura; sem `Timer`/`Tween`.

**Control Manifest Rules (Presentation)**:
- Required: `GrupoDeCartas` é a máquina de 8 estados com relógio injetado; animações por `t_ui`
- Forbidden: `Timer`, `create_timer`, `Tween` sem controle de pausa
- Guardrail: uma confirmação por passo

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md`:*

- [x] AC-TB-08 [L] F3 — aberta em 0 s, entrada 0,45 s: confirmar em 0,9 s descartado; em 0,95 s vale.
- [x] AC-TB-09 [L] R7 — confirmar segurado desde a abertura até 2 s: descartado; soltar e apertar em 2,1 s: vale.
- [x] AC-TB-10 [L] R7 — confirmar enfileirado antes de abrir é esvaziado e não escolhe.
- [x] AC-TB-11 [L] F3 — troca em 2,0 s (anim 0,3): confirmar em 2,5 s descartado; 2,6 s vale; trocar em 2,5 s descartado.
- [x] AC-TB-12 [L] R7/F3 — pausa 1,2 → 3,0 s: confirmar em 3,2 s descartado, 3,3 s vale; pausa 0,2 → 0,5 s: vale só a partir de 0,95 s.
- [x] AC-TB-18 [L] R12 — 10 min abertos (relógio falso): nada escolhido sozinho, sem botão de pular.
- [x] AC-TB-19 [L] R12 — Esc abre a pausa sem escolher; fechar devolve a tela no mesmo estado.
- [x] AC-TB-30 [L] R10 — da `oferta_aberta` às cartas assentadas ≤ 0,45 s; três legíveis em 0,5 s.
- [x] AC-TB-34 [L] Edge — Esc na trava abre a pausa; perder o foco da janela não pausa nem escolhe.

---

## Implementation Notes

*Derived from ADR-0012 §4–§7:*

- `abrir(cartas, trocas, t, modo)`; `processar(cmd, alvo, t)`; `estado()`.
- `t_assentou` = fim real da entrada (ou do fade com redução de movimento); trava pós-pausa = `max(fim da trava em curso, t_volta + trava_troca_ms)`.
- Apertos dentro da trava são descartados, não guardados.
- Pausa durante Trocando/Confirmando/Saindo: foco e mouse ignorados; a animação pausa e retoma.

---

## Out of Scope

- Story 003: troca, confirmação e sinais
- `production/epics/hud/story-008-menu-de-pausa-abandono-e-seed.md`: o menu de pausa

---

## Files

- `src/presentation/ui/grupo_de_cartas.gd` (completar)
- `tests/unit/tela_bencao/grupo_de_cartas_travas_test.gd`
- `tests/unit/tela_bencao/grupo_de_cartas_pausa_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tela_bencao/grupo_de_cartas_travas_test.gd`, `grupo_de_cartas_pausa_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/tela_bencao/grupo_de_cartas_travas_troca_e_sinais_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-001-modelo-de-foco-dados-da-carta-e-fileira.md`; `production/epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md` (`RelogioDeInterface`); `production/epics/input/` (contexto Bênção, esvaziar buffer, borda de subida)
- Unlocks: `production/epics/tela-de-bencao-e-carta/story-003-troca-confirmacao-e-sinais.md`
