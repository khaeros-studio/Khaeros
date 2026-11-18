# Story 001: ModeloDeFoco, DadosDaCarta e fileira (F1, F2, navegação)

> **Epic**: Tela de bênção e carta
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R1, R3, R6, R13, R15, R16, F1, F2, Game Feel)
**Requirement**: `TR-tela-bencao-001`, `TR-tela-bencao-003`, `TR-tela-bencao-004`, `TR-tela-bencao-011`, `TR-tela-bencao-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 3, 5, 11); ADR-0006: Input por passo
**ADR Decision Summary**: Um foco autoritativo único, o `ModeloDeFoco` (RefCounted), movido só pelos `ComandosDeTela` (navegar, aceitar, voltar, carta 1–3, trocar, pausar, cursor com `mouse_moveu`, clique com posição); vizinhos explícitos, política de borda (a Tela não dá a volta), foco inicial. Hover só move o foco com `mouse_moveu` e acerto no slot de layout. `DadosDaCarta` (só dados) alimenta a `CartaView`; escala `s = min(escala_ui, 1824 / largura(n))`.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: foco duplo do 4.6 neutralizado: o modelo é a verdade; a vista só espelha com `grab_focus()` (story 005).

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; teste de acerto pelo slot de layout; `CartaView` recebe `DadosDaCarta`, nunca lê `BoonDef`
- Forbidden: a UI ler `Input`/`InputEvent`; `get_global_mouse_position()`
- Guardrail: foco e escolha no quadro do aperto (≤ 16,7 ms)

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md`:*

- [x] AC-TB-01 [L] F1 — `largura(n)` = 320, 688, 1 056, 1 424, 1 792 para n = 1..5.
- [x] AC-TB-02 [L] F1 — UI 100%: s = 1 para n 1..5; UI 150%: n 3 → 1,5; n 5 → 1,018; UI 85%, n 3 → 0,85.
- [x] AC-TB-03 [L] R3 — cartas na ordem recebida, sem reordenar.
- [x] AC-TB-04 [L] F2 — n 1..5 → foco 0, 0, 1, 1, 2.
- [x] AC-TB-05 [L] R6 — A/D e ←/→ movem uma carta, sem dar a volta; ↓ vai ao botão de troca, ↑ volta.
- [x] AC-TB-06 [L] R6 — tecla 2 foca a carta 2 sem confirmar; tecla 3 com n = 2 nada; não há 4 nem 5.
- [x] AC-TB-07 [L] R6 — hover move o foco; clique só confirma a carta já em foco e fora da trava; clique fora de foco só foca; mouse parado ao abrir não rouba o foco de F2.
- [x] AC-TB-20 [L] R13 — n = 1: uma carta centralizada, foco 0; n = 2 centralizadas.
- [x] AC-TB-32 [L] Game Feel — foco responde no quadro do aperto (relógio falso).

---

## Implementation Notes

*Derived from ADR-0012 §3, §5, §11 e Key Interfaces:*

- `ModeloDeFoco.definir_alvos(n, inicial, da_volta)`, `aplicar(cmd, alvo_sob_cursor) -> int`, `focado()`.
- `DadosDaCarta` (RefCounted): `modo`, `nome` (chave), `doutrina`, `icone`, `glifo`, `icone_ganho`, `texto`, `melhoria`, `preco_chave` + `preco_valor`, `aviso_texto` (nulo por padrão).
- `GrupoDeCartas.escala(n, escala_ui)` (F1) é função pura usada pela vista.
- O `ModeloDeFoco` é compartilhado por pausa, opções, fim de run, consentimento e escolhas (épico `hud` e stories 007–009 daqui).

---

## Out of Scope

- Story 002: máquina de 8 estados e travas
- Story 005: vista e anel de foco

---

## Files

- `src/presentation/ui/modelo_de_foco.gd`, `dados_da_carta.gd`, `grupo_de_cartas.gd` (esqueleto com F1/F2) (novos)
- `tests/unit/tela_bencao/modelo_de_foco_test.gd`
- `tests/unit/tela_bencao/fileira_e_escala_test.gd`

Código atual: `app.selected` e `action_rects()` de `game_hud.gd`/`main.gd` migram para o `ModeloDeFoco` e slots de layout (ADR-0012 Migration Plan passo 4) — substituir.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tela_bencao/modelo_de_foco_test.gd`, `fileira_e_escala_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/tela_bencao/modelo_de_foco_e_fileira_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/input/` (story que entrega `ComandosDeTela` com `mouse_moveu` e clique com posição)
- Unlocks: `production/epics/tela-de-bencao-e-carta/story-002-grupo-de-cartas-estados-e-travas.md`; `production/epics/hud/story-008-menu-de-pausa-abandono-e-seed.md`; `production/epics/hud/story-010-tela-de-fim-de-run.md`
