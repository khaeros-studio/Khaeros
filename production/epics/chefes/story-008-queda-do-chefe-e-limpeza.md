# Story 008: Queda do chefe — HitstopFinal, limpeza, Morto e precedência da morte

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R8, R9, R9b.1, R9b.4; F6; Edge Cases)
**Requirement**: `TR-chefes-012`, `TR-chefes-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (§11 varredura de mortes, `subjugar`); ADR-0018 (§8 HitstopFinal); ADR-0015 (§4 passo 5); ADR-0011 (impact frame)
**ADR Decision Summary**: no passo `s`, a varredura do Combate trata Vida ≤ 0: sem `subjugavel`, `remover_morto`; com `subjugavel`, `subjugar` (fica na lista, inerte). Lacaios invocados e projéteis somem no mesmo passo, sem abate nem `ao_abater`. Hitstop de chefe 36 + impact frame. `ModuloDeChefes.chefe_vencido(id, subjugado)` (chamada direta do Combate) e, no `inicio_do_item_7()` de `s + 37`, fora de Pactos credita 6; `camara_limpa(4, chefe)` sai das Câmaras. Morte do jogador no mesmo passo vence.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: risco do ADR-0010/0011; o impact frame em si é da story 010.

**Control Manifest Rules (this layer)**:
- Required: varredura de mortes sobre retrato ordenado (ADR-0003)
- Required: Câmaras são a única emissora de `camara_limpa`; o módulo de Chefes nunca a emite
- Required: `ContaFragmentos` injetada; Nula quando ausente

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-15** Lâmina, chefe com Vida 10, 2 lacaios vivos, 6 projéteis, abates 20, jogador 60/100 com `cura_ao_abater = 4`; 14 de dano no passo `s`: lacaios e projéteis removidos em `s`, jogador 64/100, abates 21, 36 passos congelados. Com `pactos`: 60/100 e 20 abates em `s`; +4 e abate 21 só ao escolher `exorcizar`.
- [x] **AC-CH-16 / AC-CH-25** Lâmina (ou Ressonância) zera o chefe no passo 640: no passo 677 os Chefes creditam 6, não chamam `limpar_camara_chefe()`, e `camara_limpa(4, chefe)` sai das Câmaras pela lista vazia; o chefe vai a `Morto`.
- [x] **AC-CH-19** Jogador Vida 5, chefe Vida 8, no mesmo passo vivo ambos zeram (sem recusa): vence `jogador_morreu` e a run encerra em `morte`.
- [x] **AC-CH-23** Em Pactos o chefe nasce com `subjugavel = true`; em Lâmina/Ressonância, `false`; a marca não muda até o fim da luta.

---

## Implementation Notes

*Derived from ADR-0018 §8 / ADR-0015 §4:*

- `class_name ModuloDeChefes extends RefCounted` — dono do desfecho, separado da máquina de luta; `chefe_vencido`, `passo_vivo`, `escolha` (story 009).
- `ChefesNulo` para Run/Portas sem chefe (ADR-0015 §9).

---

## Out of Scope

- Story 009: `Subjugado`, `chefe_subjugado` e a escolha.

---

## Files

- `src/gameplay/chefes/modulo_de_chefes.gd`, `src/gameplay/chefes/chefes_nulo.gd`
- `src/gameplay/chefes/eventos_de_chefes.gd` (`EvChefeVencido`)
- `tests/integration/chefes/chefes_queda_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/chefes/chefes_queda_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-005-padrao-3-convergencia-e-lacaios.md`, `production/epics/chefes/story-006-defesas-e-transicao-de-fase.md`; épicos `production/epics/combate-nucleo/EPIC.md` (varredura, `subjugar`), `production/epics/economia-de-fragmentos/EPIC.md`, `production/epics/camaras-e-ondas/EPIC.md`
- Unlocks: `production/epics/chefes/story-009-subjugado-e-escolha.md`, `production/epics/chefes/story-010-apresentacao-do-chefe.md`

**Código da fatia**: nenhum equivalente; construção do zero.
