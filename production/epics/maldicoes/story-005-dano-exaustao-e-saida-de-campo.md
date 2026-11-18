# Story 005: Dano recebido, alvo travado, Exaustão síncrona e saída de campo

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R7, R8, R9, R21, F7)
**Requirement**: `TR-maldicoes-006`, `TR-maldicoes-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0010: Resolução do combate no passo; ADR-0018: IA de inimigos e chefe; ADR-0014: Telégrafos
**ADR Decision Summary**: Golpes inimigos que miram a Maldição chegam só por `ferir_maldicao` (F3 do Modificadores, sem invulnerabilidade nem hitstop), que consulta `maldicao_atingivel`. Alvo por inimigo travado no início do preparo, no telégrafo e no projétil: o golpe testa só o seu alvo. Quando a Vida chega a 0, o Combate chama `exaurir(id)` síncrono: estado `EXAUSTA`, `total_exausta`/`restante_exausta` fixados, ida à reserva, passivas removidas, `maldicao_saiu_de_campo` à IA, `atracao_fim` dos ids e troca automática se a reserva estiver `PRONTA` (sem técnica, sem recarga). `exaurir` não emite `maldicao_exausta` (emissor único: Combate).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0010) / LOW (ADR-0017, 0014, 0018)
**Engine Notes**: Sem física na regra.

**Control Manifest Rules (Core)**:
- Required: `exaurir` síncrono avisando a IA dentro dele; único caminho de dano à Maldição é `ferir_maldicao`
- Forbidden: o golpe percorrer "todos os jogadores" (testa só o alvo travado, ADR-0014)
- Guardrail: item 6.1 ≤ 0,1 ms

---

## Acceptance Criteria

- [x] AC-ML-10 (R7; emenda: `restante_atracao = 90`): Eco atraído pela Maldição conclui ataque com Maldição e jogador na geometria → só a Maldição recebe 9; jogador 0.
- [x] AC-ML-11 (R7; emenda: `restante_atracao = 60`): Maldição sai por Troca ou Exaustão → no mesmo passo `restante_atracao` zera nos dois inimigos, ficam com `restante_respiro = 30` e voltam a mirar o jogador.
- [x] AC-ML-12 (R8, F7): Baluarte (`Vida = 135`, `reducao_dano = 0,15`) atingido por dois Ecos (9 cada) no mesmo passo → `8 + 8 = 16` (`Vida = 119`), `hitstop = 0`, atingível no passo seguinte.
- [x] AC-ML-13 (R9, F2): Baluarte com `Vida = 5` sofre 8 → no mesmo passo vai à reserva `Exausta` (`restante_exausta = 600`), `vulto_mudo` entra sem gastar recarga e sem técnica; após 600 passos vivos o Baluarte fica `Pronta` com `Vida = 68`.
- [x] AC-ML-30 (R21): 3 Ecos atraídos, o 1º deixa a Maldição com `Vida ≤ 0` no item 7 → `maldicao_saiu_de_campo` chamada dentro de `exaurir`; o 2º e o 3º já leem o jogador no mesmo item 7; `fator_andar_atraido` deixa de valer.

---

## Implementation Notes

- Implementar `exaurir(maldicao_id)` e `fator_andar_atraido(player_id)` do contrato com Combate e IA.
- `total_exausta = passos(recuperacao_exausta_s × mult_recuperacao) × (1 − reducao_da_especie)` fixado no momento (R19).
- A que entra só age no 6.1 seguinte. Emite `EvMaldicaoTrocada(modo = automatica)`.
- Testes com Combate real e IA real se o épico `ia-de-inimigos-e-elites` estiver pronto; senão dublê da porta da IA (ADR-0017: dependência mútua com 0018 só por interface).

---

## Out of Scope

- 006: contagem da Exaustão e regeneração; 008: regras de atração do Chamado.

---

## Files

- `src/gameplay/maldicoes/modulo_de_maldicoes.gd` (exaurir, descontar_vida)
- `tests/integration/maldicoes/dano_exaustao_e_saida_de_campo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/maldicoes/dano_exaustao_e_saida_de_campo_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-004-ataque-basico-pela-r20.md`; épicos `production/epics/combate-nucleo/` (`ferir_maldicao`), `production/epics/telegrafos/` (alvo travado), `production/epics/ia-de-inimigos-e-elites/` (alvo efetivo, `maldicao_saiu_de_campo`)
- Unlocks: `production/epics/maldicoes/story-006-contadores-regeneracao-e-dupla-que-cresce.md`
