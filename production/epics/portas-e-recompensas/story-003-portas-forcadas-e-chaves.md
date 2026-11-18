# Story 003: Portas forçadas, chaves por índice e consumo fixo

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (R6, R6-P, R7, R12-P)
**Requirement**: `TR-portas-001`, `TR-portas-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico; ADR-0015: Ciclo da run e composição (§4)
**ADR Decision Summary**: o fluxo `portas` usa a chave `(regiao, i)` vinda da Run e consome 4 reais por escolha livre; portas forçadas (`santuario` depois do 2, `chefe` depois do 5) consomem 0 e não reordenam outros fluxos. Livres no Limiar depois de 0, 1, 3, 4.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: nenhuma API de engine.

**Control Manifest Rules (this layer)**:
- Required: o consumo dos fluxos não depende de haver encontro, dublê ou perfil (ADR-0015 Constraints)
- Forbidden: sorteio da porta `chefe`; `randf`/`shuffle`
- Guardrail: mesma seed e mesmo índice → mesmas portas

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story (os AC-PR-08 e 10 antigos valem só onde não contrariam os da emenda):*

- [x] **AC-PR-32** Depois do índice 4: 2 ou 3 portas livres, 4 reais do fluxo com a chave do índice 4; depois do 5: 1 porta `chefe`, 0 reais; depois do 6: nenhuma. A porta `ultima` não sai em nenhuma run do Limiar.
- [x] **AC-PR-33** As escolhas livres do Limiar usam as chaves 0, 1, 3 e 4; as forçadas (depois do 2 e do 5) consomem 0. Mesma seed: mesmas portas, com ou sem encontro (R12-P).
- [x] **AC-PR-10 (parte vigente)** Cada escolha de combate consome exatamente 4 reais (n = 2 ou 3); o jogador em outra posição ou com outra Vida não muda o estado do fluxo; mesmas portas independentemente das escolhas anteriores.
- [x] **AC-PR-08 (parte vigente)** Próxima é o santuário: 1 porta `santuario`; é o chefe: 1 porta `chefe`; nenhuma consome o fluxo. (A porta `ultima` só existe em regiões com `camaras_jogaveis = 6`; manter o caminho e testá-lo com a `RegionDef` dublê de 6.)

---

## Implementation Notes

*Derived from ADR-0005 / ADR-0015 §4:*

- `Portas.portas_para(i)` decide pelo `run.proxima(i)`: `santuario` → forçada; `chefe` → forçada (trio `(portas, 0, 5)` não consumido); `combate` → `SorteioDePortas` com o fluxo chaveado em `(regiao, i)`; `fim_da_run` → nenhuma.
- Teste do "com ou sem encontro": montar com `VinculoNulo` e com dublê de encontro e comparar o estado do fluxo.

---

## Out of Scope

- Story 005/006: quando as portas são pedidas.
- Story 008: desenho das portas.

---

## Files

- `src/gameplay/portas/portas.gd` (método de decisão das portas)
- `tests/unit/portas/portas_forcadas_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/portas/portas_forcadas_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-002-sorteio-das-portas-livres.md`; `production/epics/run-e-regioes/story-003-sequencia-da-regiao.md` (`run.proxima(i)`)
- Unlocks: `production/epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md`

**Código da fatia**: nenhum equivalente; construção do zero.
