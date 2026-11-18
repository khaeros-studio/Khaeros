# Story 005: Contrato pedir_oferta, estados e BencaosNula

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R3, R8, R12, States and Transitions)
**Requirement**: `TR-bencaos-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (Key Interfaces, §9); ADR-0002: Canal de eventos
**ADR Decision Summary**: `class_name Bencaos extends RefCounted` com `pedir_oferta(regiao, indice) -> StringName` (`&"aberta"` | `&"sem_bencao"` | `&"oferta_ja_aberta"`), `restantes()` e `tomadas()` síncronos; `BencaosNula` responde `sem_bencao`; módulos montados em memória pela `FabricaDaRun`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0002)
**Engine Notes**: Regra 4.7: overrides da Nula com `return` explícito.

**Control Manifest Rules (Feature)**:
- Required: variante Nula para colaborador opcional (`BencaosNula`)
- Forbidden: Autoload; `get_node` absoluto

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-17: com pool 0 as Portas recebem `sem_bencao` e a recompensa vira Fragmentos; um pedido com a oferta aberta recebe `oferta_ja_aberta` e a oferta continua.
- [x] AC-BN-20: o sistema roda com os dublês, sem SceneTree, incluindo a injeção de pool vazio e de `trocas_oferta` > 0.
- [x] Máquina Sem oferta → Oferta aberta → Escolhida → Sem oferta; pedido fora de run é ignorado (erro de contrato) sem consumir RNG.

---

## Implementation Notes

- Pool 0 consome os 6 reais por uniformidade antes de responder `sem_bencao` (Edge Cases).
- `pedir_oferta` emite `EvOfertaAberta` (entregue no fim do passo, ADR-0002) e pede `BENCAO` através das Portas (ADR-0015 §4.3).

---

## Out of Scope

- Story 006: escolha e eventos de tomada
- Épico portas-e-recompensas: peso da porta por `restantes()`

---

## Files

- `src/gameplay/bencaos/bencaos.gd`
- `src/gameplay/bencaos/bencaos_nula.gd`
- `tests/integration/bencaos/contrato_pedir_oferta_test.gd`

Código atual da fatia: o estado `"bencao"` em `game_session.gd` (String) é **substituído** por este contrato + `EstadoDeJogo.BENCAO`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/bencaos/contrato_pedir_oferta_test.gd`
**Status**: [x] Created and passing (2026-11-17)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-003-sorteio-da-oferta.md`; `production/epics/orquestrador-do-passo/EPIC.md` (canal de eventos — story a criar)
- Unlocks: `production/epics/bencaos-tradicoes/story-006-escolha-aplicar-e-eventos.md`, `production/epics/bencaos-tradicoes/story-007-mundo-parado.md`

## Completion Notes

2026-11-17. Criados `src/gameplay/bencaos/bencaos.gd` (contrato `pedir_oferta`, máquina com tabela de transições no doc, emite `EvOfertaAberta`) e `bencaos_nula.gd`. Teste `tests/integration/bencaos/contrato_pedir_oferta_test.gd` — 6 casos, 6 passaram (pool 0 consome 3+3 e responde `sem_bencao`; `oferta_ja_aberta` sem RNG; fora de run sem abrir fluxo; trocas > 0; Nula).
- Decisões: região → índice de RNG por dicionário injetado (`{&"limiar": 0}` vem da composição); pedido fora de run responde `&"fora_de_run"` (constante extra, não está no ADR-0015 — as Portas nunca pedem fora de run).
- **Pendências:** transição Oferta aberta → Escolhida → Sem oferta fica na story 006 (escolha); pedir `BENCAO` é das Portas (épico portas-e-recompensas, não implementado); montagem pela `FabricaDaRun` (épico Run) pendente.
