# Story 002: Teto do saldo e EconomyRates no catálogo

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R1, R2, F1, Tuning Knobs, Edge Cases)
**Requirement**: `TR-economia-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0015: Ciclo da run e composição (§6)
**ADR Decision Summary**: Tuning vem de recursos `.tres` listados no manifesto do catálogo, validados (V1–V11) e entregues por cópia; `EconomyRates` só guarda `fragmentos_provacao` e `saldo_max` — cada taxa tem um dono (porta na `RewardTable`, vitória no `RunTuning`, chefe na `RegionDef`).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004)
**Engine Notes**: Resource `.tres` e `duplicate_deep` conforme ADR-0004; conferir em `docs/engine-reference/godot/` antes de usar `duplicate_deep`.

**Control Manifest Rules (Feature)**:
- Required: dependências no `_init`; valores de tuning do catálogo validado
- Forbidden: números de gameplay hardcoded; taxa duplicada em dois donos
- Guardrail: conta monta em memória, sem cena

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md`, scoped to this story:*

- [x] AC-EF-08: saldo 999 998, `creditar(porta, 3)` → saldo 999 999, `coletados_run` soma 2, `saldo_no_teto` emitido, `saldo_mudou` com delta +2.
- [x] AC-EF-09: saldo 999 999, `creditar(porta, 2)` → nenhum `saldo_mudou`, `saldo_no_teto` emitido, saldo igual.
- [x] AC-EF-29: o `saldo_no_teto` dos dois casos acima chega ao ouvinte (dublê de HUD).
- [x] AC-EF-30: a conta monta em memória só com `EconomyRates` (`fragmentos_provacao`, `saldo_max`), sem cena; `fragmentos_base` não existe nela e `creditar(chefe, 6)` funciona sem dado de taxa.

---

## Implementation Notes

*Derived from ADR-0004 e ADR-0015:*

- `EconomyRates` (Resource) com `saldo_max` (padrão 999 999, faixa 9 999–2 147 483 647) e `fragmentos_provacao` (3, faixa 0–10); listado no manifesto explícito do catálogo e validado na carga.
- F1: `efetivo = min(q, saldo_max − saldo)`; se `efetivo < q`, emite `saldo_no_teto`; com efetivo 0 não sai `saldo_mudou`.
- A conta não lê nenhuma taxa de porta, vitória ou chefe: quem chama passa a quantidade.

---

## Out of Scope

- Story 001: contrato básico de `creditar`
- Valores de `RewardTable`, `RunTuning` e `RegionDef` (épicos portas-e-recompensas, run-e-regioes, conteudo)

---

## Files

- `src/content/economy_rates.gd`
- `assets/data/` — `economy_rates.tres` de fábrica (caminho final segue o manifesto do épico `conteudo`)
- `src/gameplay/economia/conta_fragmentos.gd`
- `tests/unit/economia/conta_teto_test.gd`

Código atual da fatia: `session_catalog.gd` (JSON) não ganha `EconomyRates`; o recurso entra direto no catálogo `.tres` do ADR-0004.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/economia/conta_teto_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/economia-de-fragmentos/story-001-conta-creditar-e-eventos.md`; `production/epics/conteudo/EPIC.md` (manifesto e validação do catálogo — story a criar)
- Unlocks: `production/epics/economia-de-fragmentos/story-004-leitura-nula-e-composicao.md`

## Completion Notes

**2026-11-16 (gameplay-programmer).** Arquivos: `src/content/economy_rates.gd` (já existia do épico conteudo; regras apertadas para as faixas do GDD: `saldo_max` 9 999–2 147 483 647, `fragmentos_provacao` 0–10, mais doc), `assets/data/economy_rates/economy_rates.tres` (fábrica: 999 999 / 3), F1 em `src/gameplay/economia/conta_fragmentos.gd`; teste `tests/unit/economia/conta_teto_test.gd` (9 casos, passou). `tests/unit/content` segue verde (74 casos).

Discrepância do GDD (para o game-designer): AC-EF-08 e o exemplo da F1 dizem "saldo 999 998, q 3 → efetivo 2", mas `min(3, 999 999 − 999 998) = 1`. Implementado pela fórmula F1; o teste cobre o caso literal (efetivo 1) e a variante saldo 999 997 (efetivo 2, delta +2, o que o AC descreve).

Pendência: o `.tres` ainda não está no manifesto `res://assets/data/content_catalog.tres` (não existe; épico conteudo). Quem criar o manifesto acrescenta `(&"economy_rates", "res://assets/data/economy_rates/economy_rates.tres")`.
