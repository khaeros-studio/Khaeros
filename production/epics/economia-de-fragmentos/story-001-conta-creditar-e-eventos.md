# Story 001: ContaFragmentos — saldo, creditar e eventos

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R1, R2, R3, R8, F1)
**Requirement**: `TR-economia-001`, `TR-economia-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§6); ADR-0002: Canal de eventos
**ADR Decision Summary**: `ContaFragmentos` é `RefCounted` de escopo de sessão, criada uma vez pela `ComposicaoDaSessao` e injetada (sem singleton); `creditar(origem, quantidade) -> int` devolve o efetivo e emite `saldo_mudou`/`saldo_no_teto` pelo canal de eventos do passo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0015); o canal (ADR-0002) é HIGH, mas aqui só se emite evento
**Engine Notes**: Nenhuma API pós-cutoff obrigatória. Regra 4.7: override com retorno não-`void` precisa de `return` explícito.

**Control Manifest Rules (Feature)**:
- Required: toda criação de módulo passa por `ComposicaoDaSessao`; dependências no `_init`
- Required: `saldo` de Fragmentos é de sessão; nunca vai para `perfil.cfg`
- Forbidden: Autoload, `get_node` absoluto em lógica, `SceneTree.paused`

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md`, scoped to this story:*

- [x] AC-EF-01: conta nova tem `saldo()` = 0 e `coletados_run()` = 0.
- [x] AC-EF-02 / AC-EF-03: `creditar(porta, 2)` → saldo 2, `coletados_run` 2, um `saldo_mudou(2, +2, porta)`; três créditos (2, 3, vitória 15) → saldo 20, `coletados_run` 20, três eventos na ordem.
- [x] AC-EF-04 / AC-EF-05: quantidade 0, -1, 2.5, 2.0 (float), NaN ou origem `"abate"` → recusa `EC1`, nada muda, sem evento.
- [x] AC-EF-07 / AC-EF-21: `chefe` e `provacao` aceitas como origens válidas; `creditar` devolve o efetivo (`creditar(porta,2)` devolve 2).

---

## Implementation Notes

*Derived from ADR-0015 §6 e ADR-0002:*

- Interface do ADR: `class_name LeituraDaConta extends RefCounted` (`saldo()`, `coletados_run()`) e `class_name ContaFragmentos extends LeituraDaConta` com `_init(rates: EconomyRates, eventos: CanalDeEventos)` e `creditar(origem: StringName, quantidade: int) -> int`.
- `quantidade` é tipada `int` no contrato, mas o teste AC-EF-04 passa float/NaN: valide com `typeof(...) == TYPE_INT` no ponto de entrada (receba como `Variant` internamente se a tipagem estrita impedir o teste) e responda `EC1` pelo relator injetado.
- Origens válidas: `porta`, `vitoria`, `chefe`, `provacao` (R2/R2-P). Não existe origem `abate`/`elite`.
- `saldo_mudou(saldo, delta, origem)` é um `EventoDoPasso` no canal (ADR-0002); nenhum sinal Godot direto para a UI.
- O teto (`saldo_max`) e `saldo_no_teto` são da story 002; aqui assuma teto alto vindo de `EconomyRates`.

---

## Out of Scope

- Story 002: teto `saldo_max`, `saldo_no_teto` e `EconomyRates` no catálogo
- Story 003: `gastar`, `nova_run`, `exportar`/`importar`
- Story 004: `ContaFragmentosNula` e injeção na composição

---

## Files

- `src/gameplay/economia/leitura_da_conta.gd`
- `src/gameplay/economia/conta_fragmentos.gd`
- `tests/unit/economia/conta_creditar_test.gd`

Código atual da fatia: nenhum código da fatia cobre a Economia; construção do zero (nada de `game_session.gd` é reaproveitado).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/economia/conta_creditar_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/EPIC.md` (canal de eventos `CanalDeEventos`/`EventoDoPasso` — story a criar nesse épico)
- Unlocks: `production/epics/economia-de-fragmentos/story-002-teto-e-economy-rates.md`, `production/epics/economia-de-fragmentos/story-003-gastar-nova-run-exportar.md`, `production/epics/economia-de-fragmentos/story-004-leitura-nula-e-composicao.md`

## Completion Notes

**2026-11-16 (gameplay-programmer).** Arquivos: `src/gameplay/economia/leitura_da_conta.gd`, `conta_fragmentos.gd`, `ev_saldo_mudou.gd`, `ev_saldo_no_teto.gd`, `relator_da_economia.gd` (@abstract), `relator_da_economia_padrao.gd`; testes `tests/unit/economia/conta_creditar_test.gd` (8 casos, passou) e fixture `tests/unit/economia/fabricas_da_economia.gd`.

Decisões:
- O "CanalDeEventos" do ADR é a classe real `EventosDoPasso` (ADR-0002); `saldo_mudou` e `saldo_no_teto` são `EvSaldoMudou`/`EvSaldoNoTeto`.
- Desvio do ADR-0015 §6: `creditar(origem: StringName, quantidade: Variant)` (o ADR tipa `int`), para a R3 recusar `2.0`/NaN em vez de o GDScript converter float→int em silêncio. Validação por `typeof == TYPE_INT`.
- `EC1`/`EC2`/`saldo_insuficiente` vão a um `RelatorDaEconomia` injetado (3º parâmetro opcional do `_init`; `null` → `RelatorDaEconomiaPadrao`, que faz `push_warning`).
