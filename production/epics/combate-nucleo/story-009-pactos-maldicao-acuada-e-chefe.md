# Story 009: Pactos — Maldição aliada, acuada e chefe Subjugado

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R19–R25, F12, F13; AC l.3262–3422)
**Requirement**: `TR-combate-nucleo-019`, `TR-combate-nucleo-020`, `TR-combate-nucleo-021`, `TR-combate-nucleo-022`, `TR-combate-nucleo-023`, `TR-combate-nucleo-024`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0017: Aliados e invocações; ADR-0018: IA de inimigos e chefe; ADR-0014: Telégrafos; ADR-0002: Canal de eventos
**ADR Decision Summary**: Item 6.1 (Maldições) entre o Selo e os inimigos; Maldição na facção do jogador, fora das listas de alvos, sem fogo amigo; `aplicar_golpe_maldicao` síncrono com abate do dono; `ferir_maldicao` (F12) com `exaurir` síncrono; `ferir_acuada` (F13) sem hitstop nem número e `falhar_encontro` síncrono; chefe `subjugavel` fica Subjugado; lacaios `invocado_pelo_chefe` saem sem abate.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0017: dublês que sobrescrevem método com retorno tipado precisam de `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: Combate lê a marca `subjugavel` no estado do inimigo, nunca a Doutrina
- Required: todo golpe testa só o alvo travado e chama só o `ferir_*` da facção dele
- Forbidden: a Maldição escrever Vida de inimigo, pedir hitstop ou usar RNG

---

## Acceptance Criteria

- [x] AC-98 [L] R19 — sem fogo amigo (l.3262)
- [x] AC-99 [L] R20 — golpe da Maldição sem arma (l.3268)
- [x] AC-100 [L] R20/R8.7 — pesado da Maldição quebra o preparo (l.3273)
- [x] AC-101 [L] R20/F2 — M da Maldição (l.3278)
- [x] AC-102 [L] R14 — abate da Maldição é do dono (l.3281)
- [x] AC-103 [L] R21/F12 — dano na Maldição (l.3286)
- [x] AC-104 [L] R21.5 — sem gatilhos do jogador (l.3292)
- [x] AC-105 [L] R21.7 — Exaustão síncrona (l.3296)
- [x] AC-106 [L] R22 — projétil só testa o seu alvo (l.3301)
- [x] AC-107 [L] R22 — Saltando e saída de campo (l.3307)
- [x] AC-108 [I] R1/R23 — ordem do 6.1 (l.3311)
- [x] AC-109 [L] R14/R24 — lacaios na queda do chefe (l.3315)
- [x] AC-110 [L] R24 — chefe Subjugado em Pactos (l.3323)
- [x] AC-111 [L] R24 — resolução (l.3338)
- [x] AC-113 [L] R25/F13 — dano na acuada (l.3351)
- [x] AC-114 [L] R25.6 — falha síncrona (l.3356)
- [x] AC-115 [L] R25.7 — sem fogo amigo (l.3360)
- [x] AC-116 [L] R7 — projétil com alvo `acuada` (l.3366)
- [x] AC-117 [I] R1/R25 — mesmo passo que a câmara limpa (l.3372)
- [x] AC-118 [L] R10 — sem hitstop (l.3377)
- [x] AC-119 [L] Edge — sem encontro (l.3379)

---

## Implementation Notes

*Derived from ADR-0010, ADR-0017 and ADR-0018:*

- Lado do Combate apenas: `aplicar_golpe_maldicao`, `ferir_maldicao`, `ferir_acuada`, pedido `subjugar` à IA com projéteis removidos; eventos `maldicao_atingida`, `maldicao_exausta`, `chamado`, `chamado_indisponivel`, `chefe_vencido` e campos `autor_player_id`, `limpo_pelo_chefe`, origem `maldicao`.
- O `ModuloDeMaldicoes` (item 6.1) é do épico `maldicoes`; aqui dublê até ele existir.
- **Código da fatia**: nada cobre Pactos — construção do zero.

---

## Out of Scope

- Épico `maldicoes`: IA de aliado, troca, Chamado, reserva/Exaustão
- Épico `vinculo-e-pactos`: o encontro de pacto

---

## Files

- `src/gameplay/combate/combate.gd` (`ferir_maldicao`, `ferir_acuada`, subjugar)
- `src/gameplay/combate/eventos/` (eventos de Pactos)
- `tests/unit/combat/pactos_combate_test.gd`
- `tests/integration/combat/ordem_item_6_1_test.gd` (AC-108, AC-117)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/pactos_combate_test.gd` — must exist and pass; AC-108/AC-117 em `tests/integration/combat/ordem_item_6_1_test.gd`

**Status**: [x] Complete (`tests/unit/combat/pactos_combate_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-007-dano-no-jogador-e-varredura.md`, `production/epics/combate-nucleo/story-008-eventos-e-contratos.md`, `production/epics/maldicoes/EPIC.md`, `production/epics/ia-de-inimigos-e-elites/EPIC.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-006-besta-virote-e-chamado.md`, `production/epics/vinculo-e-pactos/EPIC.md`, `production/epics/chefes/EPIC.md`
