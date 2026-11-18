# Story 002: Montagem e máquina de fases do chefe (ciclo de 4 padrões, sem RNG, Fúria)

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R1, R2, R4, R6; F1; States and Transitions)
**Requirement**: `TR-chefes-002`, `TR-chefes-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0018: IA de inimigos e do chefe (§3, §8); ADR-0005: RNG determinístico
**ADR Decision Summary**: `ComportamentoChefe` (sem estado) usa a máquina de fases genérica do `ModuloDeIA` + `EstadoDoChefe` no `InimigoRef` (`padrao`, `em_furia`, `transicao_pendente`, `avancar_padrao_ao_sair`, `pulso_pendente`). Esperas fixas (30 inicial, 15 entre padrões), sem RNG; `padrao = (padrao + 1) mod 4` ao entrar em `RECUPERACAO`; recarga × `fator_recarga_furia` e velocidade × `mult_velocidade_furia` com `em_furia`. Timers só em passo vivo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: `@abstract` (4.5+) em `Comportamento` — **verificar** que subclasse incompleta dá erro de parse em 4.7.2; todo override tipado com `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: comportamentos sem estado; todo estado no `InimigoRef` (ADR-0018)
- Forbidden: o chefe consumir RNG; `Node`/`Timer`/`Area2D`; a IA contar o preparo por conta própria (disparo = `disparou_neste_passo`)

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-01** Na câmara 6, no corte do wipe: 4 pilares de 51 px em (390; 300), (1530; 300), (390; 750), (1530; 750); jogador em (960; 930); chefe em (960; 285) com Vida 700 (sem +5%/p), `Surgindo` 50 passos, depois `Aproximacao` com `timer = 30`, `padrao = 0`; sem consumir `layout`, `ondas`, `elites`, `spawn` ou `ia`.
- [x] **AC-CH-10** Fim dos 105 passos de recuperação do Padrão 3 na Fase 1 → `Aproximacao`, `padrao = 0`, `timer = 15`.
- [x] **AC-CH-13** Na Fase 2 (`em_furia`): andar 186,3 px/s (162 × 1,15), preparos 30/36/36/42 inalterados, recargas 36/45/54/63 (× 0,60).
- [x] (ADR-0018 Validation) Chefe com seed qualquer produz a mesma sequência de padrões e tempos.

---

## Implementation Notes

*Derived from ADR-0018 §8:*

- Engajamento: P0 por `dist ≤ alcance_engajamento_p0_px`; P1–P3 com `timer ≤ 0` em qualquer distância.
- Preparo: `telegrafos.iniciar_telegrafo(id, ataque, alvo.id, alvo.faccao)`; recusa (teto) → fica em `APROXIMACAO`.
- A montagem da arena/posição é das Câmaras (`criar_inimigo` com `subjugavel` da Doutrina); esta story testa via dublê de Câmaras.

---

## Out of Scope

- Stories 003–005: execução de cada padrão.
- Story 006: `TransicaoFase`.

---

## Files

- `src/gameplay/ia/comportamento_chefe.gd`, `src/gameplay/ia/estado_do_chefe.gd`
- `tests/unit/chefes/chefes_maquina_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chefes/chefes_maquina_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-001-dados-do-chefe-e-validacao.md`; épicos `production/epics/ia-de-inimigos-e-elites/EPIC.md` (máquina de fases genérica, `Comportamento`), `production/epics/telegrafos/EPIC.md`, `production/epics/camaras-e-ondas/EPIC.md` (câmara do chefe)
- Unlocks: stories 003–006 deste épico

**Código da fatia**: a IA da fatia (fases em `Dictionary` dentro de `game_session.gd`) não é base para o chefe — **substituída** pelo `ModuloDeIA`.
