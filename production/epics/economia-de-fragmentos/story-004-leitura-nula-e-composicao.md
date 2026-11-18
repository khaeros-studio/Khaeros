# Story 004: LeituraDaConta, ContaFragmentosNula e injeção na sessão

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R3, R8, R9)
**Requirement**: `TR-economia-003`, `TR-economia-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§6, §9); ADR-0012: UI e HUD; ADR-0002: Canal de eventos
**ADR Decision Summary**: A conta é criada uma vez pela `ComposicaoDaSessao` e injetada com escrita em Portas, Chefes e Run e como `LeituraDaConta` (sem `creditar`/`gastar`) em HUD/Telemetria/tela final; todo colaborador opcional tem variante Nula — `ContaFragmentosNula` devolve 0 e não emite nada; um `null` no `_init` vira a Nula com aviso único ao relator.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0002/ADR-0012 — canal e UI)
**Engine Notes**: Regra 4.7: a Nula sobrescreve métodos com retorno não-`void` e **deve** ter `return` explícito em todos.

**Control Manifest Rules (Feature)**:
- Required: todo colaborador opcional tem variante Nula (`ContaFragmentosNula`) com `return` explícito
- Required: escopos — menor referencia maior, nunca o contrário; quem é de sessão ouve a run por eventos
- Forbidden: `if x != null` dentro da regra; Autoload

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md` e ADR-0015 Validation, scoped to this story:*

- [x] AC-EF-06: o evento de morte de inimigo do Combate (dublê) não altera o saldo; nenhuma origem `abate`/`elite` existe.
- [x] AC-EF-26: HUD e Telemetria (dublês) recebem `saldo_mudou` em ordem, sem poder alterar a conta (a interface de leitura não expõe `creditar` nem `gastar`).
- [x] TR-economia-007 (ADR-0015 Validation): Run e Portas montadas com `ContaFragmentosNula` completam o fluxo sem erro; `creditar` na Nula devolve 0 e nada é emitido.

---

## Implementation Notes

*Derived from ADR-0015 §6/§9:*

- `ContaFragmentosNula extends ContaFragmentos`: `creditar` → `return 0`, `gastar` → `return false`, `exportar` → `return 0`, consultas → `return 0`.
- `ComposicaoDaSessao` cria a conta (escopo de sessão) e a passa à `FabricaDaRun`; HUD/Telemetria recebem o tipo `LeituraDaConta`.
- Construtores de Run/Portas trocam `null` pela Nula e avisam o relator uma vez.

---

## Out of Scope

- Story 005: ordem de crédito com Run e Portas
- Épico hud: exibição do saldo (story 007 aqui só cobre a evidência)

---

## Files

- `src/gameplay/economia/conta_fragmentos_nula.gd`
- `src/app/composicao_da_sessao.gd` (adaptar: criar e injetar a conta)
- `tests/integration/economia/conta_leitura_e_nula_test.gd`

Código atual da fatia: `src/app/main.gd` é **adaptado** — fica fino e delega a criação à `ComposicaoDaSessao` (ADR-0015 §1); `game_session.gd` não ganha conta.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/economia/conta_leitura_e_nula_test.gd`
**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/economia-de-fragmentos/story-001-conta-creditar-e-eventos.md`, `production/epics/economia-de-fragmentos/story-002-teto-e-economy-rates.md`; `production/epics/run-e-regioes/EPIC.md` (`ComposicaoDaSessao`/`FabricaDaRun` — story a criar)
- Unlocks: `production/epics/economia-de-fragmentos/story-005-ordem-com-run-e-portas.md`, `production/epics/economia-de-fragmentos/story-007-saldo-no-hud-evidencia.md`

## Completion Notes

**2026-11-16 (gameplay-programmer).** Arquivos: `src/gameplay/economia/conta_fragmentos_nula.gd` (todos os overrides com `return` explícito; `static ou_nula(conta, relator, quem)` = ponto único do "null vira Nula com aviso único"); teste `tests/integration/economia/conta_leitura_e_nula_test.gd` (6 casos, passou) com dublês de Combate, HUD/Telemetria, Run e Portas.

Pendências reais:
- `src/app/composicao_da_sessao.gd` não existe (dono: épico run-e-regioes). Não criado aqui para não colidir. Quando existir: `ContaFragmentos.new(rates_do_catalogo, eventos, RelatorDaEconomiaPadrao.new())` uma vez por sessão; passar à `FabricaDaRun` (Run, Portas, Chefes) e como `LeituraDaConta` ao HUD/Telemetria. `main.gd` não foi tocado.
- Run/Portas reais devem usar `ContaFragmentosNula.ou_nula(...)` no `_init`; o teste de TR-economia-007 roda hoje só com dublês.
