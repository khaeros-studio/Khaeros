# Story 003: IA de aliado — fio de vínculo, alvo por prioridade e passivas condicionais

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R4, R5, R22, F1)
**Requirement**: `TR-maldicoes-004`, `TR-maldicoes-016` (passivas condicionais)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0009: Atributos e modificadores
**ADR Decision Summary**: Alvo a cada passo: marca do Virote se atingível e no fio; senão o atingível mais perto do jogador no fio; senão nenhum (distância ao quadrado, empate pelo menor id). Fio com histerese (`alcance_fio_px` / `distancia_seguir_px`). Movimento em reta com `valor(velocidade)/60` corrigido por `resolver_colisao` (ADR-0008). Passivas condicionais entram como fonte `especie:<id>:<passiva>` no portador.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW
**Engine Notes**: Nenhuma API pós-corte.

**Control Manifest Rules (Core)**:
- Required: alvos iterados por id crescente; arredondamento determinístico do ADR-0009 (sem `round()`)
- Forbidden: consulta de física, `Area2D`/`ShapeCast2D`
- Guardrail: item 6.1 ≤ 0,1 ms

---

## Acceptance Criteria

- [x] AC-ML-05 (R4, F1): o Virote acerta `id = 5` (300 px) com `id = 2` a 180 px → no passo vivo seguinte o alvo é `id = 5`; sem marca e dois inimigos a 200 px, vence o menor id.
- [x] AC-ML-06 (R5, F1): `vulto_mudo` (6,75 px/passo) com `d_jog = 493,5 px` → no 1º passo limpa o alvo e entra em `Seguindo`, ignora inimigos enquanto `d_jog > 105 px` e no 58º passo atinge `d_jog ≤ 105 px`, voltando a escolher alvo.
- [x] AC-ML-31 (R22): *Espreitador* perseguindo a marca → fonte `especie:espreitador_da_fenda:faro` e `valor(velocidade) = 500,25 px/s`; marca vai para fora do fio → a fonte sai no mesmo passo e a velocidade volta a 435.

---

## Implementation Notes

- Sub-passo 7 do 6.1. A marca vem do `EvAcertoDeArma` do Virote do dono lido na lista do passo; limpa quando o alvo deixa de ser atingível.
- `estourou_fio = true` limpa alvo e marca entra em `SEGUINDO` até `d_jog ≤ distancia_seguir_px`.
- Não colide com jogador nem inimigos (R1); sem busca de caminho.
- Emite `EvFioEstourou` e `EvMarcaViroteMudou` (formato fechado na story 009).

---

## Out of Scope

- 004: o ataque em si; 008: Chamado; 006: espelho de bênçãos (`EspelhoDaDupla`).

---

## Files

- `src/gameplay/maldicoes/ia_de_aliado.gd`
- `tests/unit/maldicoes/ia_de_aliado_fio_e_alvo_test.gd`

Código da fatia: `src/gameplay/movement.gd` não é reaproveitado (a colisão vem do `resolver_colisao` do épico `movimento-e-esquiva`).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/maldicoes/ia_de_aliado_fio_e_alvo_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-002-modulo-dupla-e-faccao.md`; épico `production/epics/movimento-e-esquiva/` (`resolver_colisao`)
- Unlocks: `production/epics/maldicoes/story-004-ataque-basico-pela-r20.md`
