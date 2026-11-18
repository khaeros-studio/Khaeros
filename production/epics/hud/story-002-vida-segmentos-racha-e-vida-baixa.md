# Story 002: Vida — segmentos, largura, rachar, escudo, recusas e Vida baixa

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R3, R4, R5, F1, F2, F3, Edge Cases)
**Requirement**: `TR-hud-005` (rachar espera o hitstop e `preco_revelado`), `TR-hud-004` (parte lógica: valor da vinheta publicado)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0011: Pipeline visual
**ADR Decision Summary**: O número e o preenchimento mudam no passo do evento; o rachar por dano espera `hitstop_ativo() == false` e o rachar por preço de bênção espera `preco_revelado`. A vinheta de Vida baixa é calculada pelo HUD (F3, histerese, opção 6) e publicada como valor; quem desenha no Pós (z 50) é o Pipeline.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0011 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: lógica pura em `RefCounted`, sem API de engine; testável com fontes e relógio falsos.

**Control Manifest Rules (Presentation)**:
- Required: HUD lê por consulta; animações por `t_ui`
- Forbidden: guardar estado de jogo; `Tween` sem controle de pausa
- Guardrail: UI ≤ 80 draw calls (ADR-0011)

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md`:*

- [x] AC-HD-01 [L] F1 — segmentos (34/80 → 8 seg., 3 cheios, 4º a 0,4; 100 → 10; 20 → 2; 85/85 → 9, o 9º com capacidade 5 e cheio).
- [x] AC-HD-02 [L] F2 — largura (Vida 100 → 347 px; 150 → 480 px com `segmento_px'` 29,2; teto antes da escala; 150% com Vida 100 → 520,5 px).
- [x] AC-HD-03 [L] R3 — rachar (perda 10 racha o segmento; escudo absorvendo tudo não racha; perda 25 de 34/80 racha 4º parcial, 3º, 2º e parte do 1º; número ≤ 1 passo).
- [x] AC-HD-04 [L] R3 — Fundo do Poço (marca em `limiar_vida` do dado, 0,40 → 40%; sem dado 50%; sem bênção nenhuma).
- [x] AC-HD-05, AC-HD-06, AC-HD-07 [L] F3 — Vida baixa liga/desliga com histerese em inteiros (100: liga ≤ 25, desliga > 30; 20: liga ≤ 5, desliga > 6).
- [x] AC-HD-08 [L] R4 — vinheta nunca passa de 8% por borda nem 40% de opacidade, mesmo com a opção 6 em 100%.
- [x] AC-HD-09 [L] R5 — escudo e recusas (nada sem eles; recusas 2 → 2 pontos; 5 → máx. 3; escudo 20 sobre 90/100 → faixa de 10, some ao zerar).
- [x] AC-HD-22 [L] F3 — `vida_max` 100 → 150 com Vida 25 → 75: 15 segmentos e Vida baixa desliga.
- [x] AC-HD-23 [L] Edge — `recusou_morte`: barra salta à Vida nova sem animação; moldura partida liga se ≤ limiar.
- [x] AC-HD-35 [L] R3 — `preco_revelado`: número e preenchimento mudam no quadro de `escolher`; nada racha antes de `preco_revelado`; ao recebê-lo, rachar começa (0,25 s); traço dourado voa ao grupo inferior.

---

## Implementation Notes

*Derived from ADR-0012 §1, §2:*

- `ModeloDaVida` (RefCounted) dentro do `ModeloDoHud`; segmentos e largura são funções puras F1/F2 sobre `HudTuning`.
- Rachar: fila de animações pendentes; libera com `hitstop_ativo() == false` (dano) ou com o sinal `preco_revelado` (preço de bênção). O valor nunca espera.
- Vinheta: o modelo publica `{ligada, borda, opacidade, estatica}` (opção 6 escala; opção 5 deixa estática); o Pipeline (ADR-0011) desenha no Pós.
- Marca do Fundo do Poço: `limiar_fundo_do_poco(player_id)` (< 0 = sem bênção).

---

## Out of Scope

- Story 006: desenho em `Control`, vinheta no Pós (integração com Pipeline) e capturas AC-HD-26/28
- Story 007: aplicação/persistência das opções 5, 6, 8, 9, 10

---

## Files

- `src/presentation/ui/modelo_da_vida.gd` (novo)
- `tests/unit/hud/vida_segmentos_e_racha_test.gd`
- `tests/unit/hud/vida_baixa_histerese_test.gd`

Código atual: a barra de `game_hud.gd` serve só de referência visual; substituir.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/hud/vida_segmentos_e_racha_test.gd`, `tests/unit/hud/vida_baixa_histerese_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/hud/modelo_e_vida_hud_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md`
- Unlocks: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`; `production/epics/tela-de-bencao-e-carta/story-003-troca-confirmacao-e-sinais.md` (AC-TB-29 usa o HUD)
