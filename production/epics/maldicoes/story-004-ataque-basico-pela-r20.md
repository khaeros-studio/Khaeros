# Story 004: Ataque básico da Maldição pelo impacto do Combate (R20) e habilidade Primordial

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R6, R16, F3)
**Requirement**: `TR-maldicoes-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0017: Aliados e invocações
**ADR Decision Summary**: A geometria do golpe é do módulo (`GeometriaDeAcerto`); para cada alvo chama `combate.aplicar_golpe_maldicao(...)` com `player_id` do dono. O Combate aplica a R8 com `de_arma` falso e `autor_player_id` = dono: sem contador de acerto, Fluxo, `golpe_*` nem hitstop. `M` = `portador.multiplicador_de_dano` no impacto. A habilidade Primordial é um `TecnicaDef` com gatilho "a cada N ataques concluídos", executado pelo `ExecutorDeTecnica`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0010) / LOW (ADR-0017)
**Engine Notes**: ADR-0010 proíbe física 2D na regra (física do 4.7 fora da referência).

**Control Manifest Rules (Core)**:
- Required: todo dano a inimigo por `aplicar_golpe_maldicao`
- Forbidden: a Maldição escrever Vida de inimigo, pedir hitstop, usar RNG
- Guardrail: item 6.1 ≤ 0,1 ms

---

## Acceptance Criteria

*Valores da emenda Pactos (2026-11-15) prevalecem:*

- [x] AC-ML-07 (R6, F3): `vulto_mudo` contra Eco Perdido (30 HP), 30 passos (`P=8, E=6, R=16`) → Eco recebe **9** no passo de execução, `hitstop = 0`, Fluxo `+0`, contador de acertos da arma inalterado.
- [x] AC-ML-08 (R6): o básico abate um Eco com 8 HP → abate creditado ao `player_id` do dono, jogador `70/90 → 74/90` com `cura_ao_abater = 4`, hitstop de abate do Combate R14 aplicado.
- [x] AC-ML-09 (R6, F3): *Quebra-Limiar* do Baluarte no Eco no passo 10 do preparo → **12,6** de dano, preparo cancelado com "Quebrou!" (24 passos de recuperação) e empurrão de 900 px/s.
- [x] AC-ML-21 (R16, F3): `soberano_do_limiar`, 3 ciclos (108 passos) → cada golpe **9,8**, *Pulso de Soberania* `+3` pesado (`empurrao = 900`) em 135 px, total **32,4** em 1,80 s (**18,00 DPS**); o Pulso aplica 60 passos de atração só a inimigo livre.

---

## Implementation Notes

- Sub-passo 8 do 6.1: ciclo por fases (preparo/execução/recuperação) com contador de fase; ataques concluídos contam para o gatilho Primordial.
- `ExecutorDeTecnica.executar(t, autor, ctx)` (funções `static`) é criado aqui e reaproveitado nas stories 007 e 008.
- Atração do Pulso via `ia.atrair(...)` com a duração do `TecnicaDef` (limitada por ML1).
- Emite `EvMaldicaoGolpe`.

---

## Out of Scope

- 005: dano recebido pela Maldição; 007: técnicas de troca; 008: limites de atração (sem renovação/respiro).

---

## Files

- `src/gameplay/maldicoes/ataque_da_maldicao.gd`, `executor_de_tecnica.gd`, `contexto_da_tecnica.gd`
- `tests/integration/maldicoes/ataque_basico_pela_r20_test.gd`

Código da fatia: o dano direto de `src/gameplay/game_session.gd` não é usado; o caminho é o `aplicar_golpe_maldicao` do épico `combate-nucleo`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/maldicoes/ataque_basico_pela_r20_test.gd` (Combate real, IA em dublê)
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-003-ia-de-aliado-fio-e-alvo.md`; épico `production/epics/combate-nucleo/` (`aplicar_golpe_maldicao`, R8, varredura de abates); épico `production/epics/ia-de-inimigos-e-elites/` (cancelamento de preparo "Quebrou!")
- Unlocks: `production/epics/maldicoes/story-005-dano-exaustao-e-saida-de-campo.md`, `production/epics/maldicoes/story-007-troca-e-tecnica-combinada.md`
