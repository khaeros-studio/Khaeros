# Story 005: Unidades do Godot e funções F1–F8

> **Epic**: conteudo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R6, F1–F8)
**Requirement**: `TR-conteudo-006` (unidades do Godot; TICK_RATE 60 conferido na carga; F7 segundos para passos)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0001)
**ADR Decision Summary**: Os dados usam unidades do Godot; o passo de 1/60 s vem de uma constante única conferida na carga contra `physics_ticks_per_second`; conversões são funções puras.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: nenhuma API pós-corte; usar a função de arredondamento própria quando o GDD exigir meio longe do zero (sem `round()`).

**Control Manifest Rules (this layer)**:
- Required: constante de passo única; funções puras sem estado; testes por tolerância 1e-6 salvo indicação.
- Forbidden: `round()`/`roundi()` como fonte de arredondamento; ler `Engine` na função pura (o valor entra por parâmetro).
- Guardrail: n/a.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-28 (F1): 16 → 0,266667 s; 26 → 0,433333 s; 0 → 0.
- [x] AC-29 (F2/F3): 1,7 → 153; 4,3 → 387; 11 → 990 px/s; empurrão 5 → 450 e 4 → 360; limiar da parede 7 → 630; 0,06 → 3,6; 0,12 → 7,2; 0,04 → 2,4 por segundo.
- [x] AC-30 (F4): 95 → 142,5 px; arena não uniforme (1280×800) recusa a importação.
- [x] AC-31 (F5): 0,35 → 69,51°; 0,5 → 60,00°; 0,1 → 84,26°; −1 → 180° (tol. 0,005°); 0,999 (< 5°) é erro; alvo exatamente em θ é acertado.
- [x] AC-32 (F6): 50 ticks a 990 px/s → `life_s` 0,8333 e `reach_px` 825 no relatório; `life_s = 0` é erro V2.
- [x] AC-33 (F7): 0,2667 s → 16; 0,7 → 42; 16/60 → 16 (não 17); 0,025 s → 2; 0,005 → 1 com aviso não bloqueante; t = 0 em campo que aceita zero → 0; t = 0 em campo que não aceita → erro V2.
- [x] AC-35 e AC-36 (F8): curva de elite (0,05; 0,02; x_min 3; piso 0; teto 0,25) com x = 2, 3, 5, 12 → 0; 0,11; 0,15; 0,25; piso 0,1 com x < x_min → 0; `sem_teto = true` sem limite; piso > teto erro V2 citando `y_floor` e `y_cap`.
- [x] AC-19: `physics_ticks_per_second = 30` gera erro bloqueante na carga.

---

## Implementation Notes

Módulo estático puro `Unidades` (funções sem estado; a "constante única" `TICK_RATE` fica nele e é a mesma consumida pelo orquestrador, épico `orquestrador-do-passo` story 003). `LinearCurveDef` é `Resource` (story 002); a F8 é a função que o avalia. Fórmulas completas na seção Formulas do GDD (ler por seção na implementação).

---

## Out of Scope

- Importação que aplica F1–F6 (story-010); mensagens V2 (story-004).

---

## Files

- `src/content/unidades.gd`, `curva_linear.gd`
- `tests/unit/content/unidades_f1_f8_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/unidades_f1_f8_test.gd` — must exist and pass.

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `story-002-tipos-de-definicao.md`
- Unlocks: `story-004-validadores-v1-v11.md`, `story-010-canone-importador-paridade.md`

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

Arquivos: `src/content/unidades.gd` (`Unidades`: `TICK_RATE` 60, `UNIT_TO_PX` 1,5, F1–F7, arredondamento próprio meio-longe-do-zero, `verificar_duracao`, `verificar_tick_rate`), `src/content/curva_linear.gd` (`CurvaLinear.avaliar`, F8); `tests/unit/content/unidades_f1_f8_test.gd`.
Alterados (mesmo épico): `linear_curve_def.gd` (campo `sem_teto`; doc corrigida para `base + slope × x`, que é a fórmula do GDD e bate com os exemplos), `esquema_de_definicao.gd` (regra entre campos aceita `exceto_se`), `v2_faixas.gd` (pula a regra com `sem_teto`; campos `*_s` passam pela F7: abaixo de meio passo = aviso), `carregador_de_catalogo.gd` (confere `physics_ticks_per_second` na carga, valor injetável; AC-19), `tests/unit/content/fabricas_de_catalogo.gd` (tabela com `sem_teto`).

Testes: 14 casos, 14 passaram (suíte completa de `tests/unit/content` + `tests/integration/content`: 78/78).

Decisões: Vector2 é float32, por isso o teste de "alvo exatamente em θ" usa cosseno em float64; `acerta_arco` tem tolerância 1e-9. A linha `reach_px` é gerada por `Unidades.linha_de_alcance()`; ela só entra no relatório quando a importação existir (story 010).
Pendências: `life_s = 0` como V2 dentro de `AttackDef.params` (dicionário) não é checado pela V2 genérica. A função `verificar_duracao` já trata o caso; ligá-la fica para a importação (story 010). O orquestrador ainda tem a própria constante em `src/gameplay/` (fatia): migrar para `Unidades.TICK_RATE` é trabalho do épico orquestrador.
