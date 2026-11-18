# Story 006: Contadores por passo vivo, regeneração, espelho das bênçãos e a dupla que cresce

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R10, R15, R24, F2)
**Requirement**: `TR-maldicoes-009`, `TR-maldicoes-016` (espelho `dano_todo_pct`/`velocidade_pct`), `TR-maldicoes-002` (dupla cresce no meio da run)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0009: Atributos e modificadores; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Sub-passo 2 do 6.1: `recarga_troca −1`, `restante_exausta −1` (zera → `PRONTA` com `vida_retorno_frac × vida_max`, `maldicao_pronta`), regeneração F2 com acumulador fracionário, `portador.avancar(1)`. Hitstop, pausa e Transição não chamam o 6.1. `EspelhoDaDupla` aplica/remove `espelho:<id>` nos portadores da dupla para tipos em `tipos_propagados_maldicao`, nunca gatilho. `acrescentar_a_dupla(player_id, def, vida)` cria `MaldicaoRef` nova `PRONTA` na reserva com portador montado como no começo da run, espelhos incluídos. `mult_recuperacao` e `bonus_dano_basico` lidos do Vínculo só na criação da run.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW
**Engine Notes**: Arredondamento determinístico do ADR-0009 (sem `round()`).

**Control Manifest Rules (Core)**:
- Required: `MaldicaoRef` com portador próprio, nunca destruído na Exaustão
- Forbidden: propagar gatilho ou tipo fora de `tipos_propagados_maldicao`
- Guardrail: item 6.1 ≤ 0,1 ms

---

## Acceptance Criteria

- [x] AC-ML-14 (R10, F2): Baluarte `Pronta` na reserva com `68/135` e `acum_regen = 0` → em 596 passos vivos sobe inteiro até exatamente `135/135` e `acum_regen` zera.
- [x] AC-ML-20 (R15): com uma Maldição em `Preparo` e outra `Exausta` (`restante_exausta = 300`), 6 passos de hitstop (ou Pausa/Transição) não avançam posição, ciclo de ataque, `restante_exausta`, `acum_regen` nem `recarga_troca`.
- [x] AC-ML-33 (R24): dupla de 1 e pacto do *Espreitador* com acuada em `Vida = 40` e jogador com `dano_todo_pct +0,20` → *Espreitador* na reserva `Pronta` `40/95`, `acum_regen = 0`, portador novo com espelho `+0,20` (M `1,20`); no passo seguinte `troca_disponivel` pode ficar verdadeiro.
- [x] AC-ML-34 (R24): *Soberano* no nível 3 e *Vulto* no nível 4 → `total_exausta = 432` e o golpe do *Vulto* causa `9 × 1,05 = 9,45`.

---

## Implementation Notes

- `EspelhoDaDupla` é injetado no caminho por onde fontes entram no portador do jogador (épico `modificadores`); valor × `fator_propagacao_maldicao`, mesma operação e duração restante.
- Bônus de vínculo (`vinculo:<curse_id>`) aplicado uma vez na criação da run; o módulo não relê o Vínculo durante a run.

---

## Out of Scope

- A decisão de pacto e a Vida da acuada: `production/epics/vinculo-e-pactos/story-006-consentimento-portas-e-dupla.md`.

---

## Files

- `src/gameplay/maldicoes/espelho_da_dupla.gd`, `modulo_de_maldicoes.gd` (sub-passo 2, `acrescentar_a_dupla`)
- `tests/unit/maldicoes/contadores_regeneracao_e_dupla_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/maldicoes/contadores_regeneracao_e_dupla_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-005-dano-exaustao-e-saida-de-campo.md`; épico `production/epics/modificadores/`
- Unlocks: `production/epics/maldicoes/story-007-troca-e-tecnica-combinada.md`, `production/epics/vinculo-e-pactos/story-006-consentimento-portas-e-dupla.md`
