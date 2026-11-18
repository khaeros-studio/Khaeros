# Story 001: RewardTable no catálogo e validação PV1–PV8

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (Formulas › Faixas da `RewardTable`, Validação da `RewardTable`; R10)
**Requirement**: `TR-portas-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: catálogo `.tres` com manifesto explícito, validadores declarados por esquema (campos, tipos, limites, regras entre campos) e erro que impede a run de começar; avisos não bloqueiam.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: MEDIUM
**Engine Notes**: `Resource` tratado como imutável; cópia mutável só por `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (ADR-0004). Verificar o comportamento de `duplicate_deep` em 4.7.2 se a story criar cópia.

**Control Manifest Rules (this layer)**:
- Required: toda criação de módulo passa por `ComposicaoDaSessao`/`FabricaDaRun`; dependências no `_init` (ADR-0015)
- Required (Foundation, catálogo): o esquema distingue campo ausente de valor gravado (ADR-0004)
- Forbidden: número de jogo literal no código das Portas — tudo vem da `RewardTable`

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-18** `chance_3_portas` fora de [0, 1], `cura_pct` fora de [0, 1], `fragmentos_passo_prof` 0 ou `primeira_recompensa` = `provacao`: erros PV1 e PV2; `pesos` com `provacao` = 1: erro PV7; a run não começa.
- [x] **AC-PR-19** O catálogo de fábrica não gera nenhum aviso PV3 a PV6; cura 0 com `chance_3_portas` 0,3: PV3 (e PV6); `cura_pct` 0,45: PV4; pesos 1 / 1 / 4: PV5; campo fora da faixa: PV6.
- [x] **AC-PR-37** Com um pool de bênçãos de 4 e `k` = 4: aviso PV8; o catálogo de fábrica não gera PV8 se o pool tiver ≥ 5.

---

## Implementation Notes

*Derived from ADR-0004:*

- `RewardTable` é um `Resource` de tuning no manifesto do catálogo; as Portas recebem a instância já validada por injeção (nunca leem o catálogo sozinhas).
- Os validadores PV1–PV8 entram no mesmo mecanismo de validação do catálogo (erros bloqueiam a carga; avisos vão ao relator). PV8 cruza com o pool de `BlessingDef` (emenda Pactos).
- Testes montam `RewardTable` em memória (fábrica de fixture), sem disco.

---

## Out of Scope

- Story 002/003: uso dos valores no sorteio.
- Story 004: uso nas fórmulas F1/F4.

---

## Files

- `assets/data/tuning/reward_table.tres` (novo, valores de fábrica do GDD)
- `src/gameplay/portas/reward_table.gd` (classe do Resource)
- `src/gameplay/portas/validacao_reward_table.gd` (PV1–PV8, registrada no validador do catálogo)
- `tests/integration/portas/portas_validacao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/portas/portas_validacao_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: épico `production/epics/conteudo/EPIC.md` (story do carregador/validador do catálogo — ADR-0004); épico `production/epics/bencaos-tradicoes/EPIC.md` (pool de bênçãos, para PV8)
- Unlocks: `production/epics/portas-e-recompensas/story-002-sorteio-das-portas-livres.md`, `production/epics/portas-e-recompensas/story-004-conceder-recompensa.md`

**Código da fatia**: nenhum equivalente; construção do zero. `session_catalog.gd` não ganha campos de portas (o catálogo novo é do épico `conteudo`).
