# Story 009: Câmara do chefe — sem sorteio, Subjugado e limpar_camara_chefe

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R8-P, R10-P, R14, R14-P, R18-P)
**Requirement**: `TR-camaras-013`, `TR-camaras-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4.5); ADR-0018: IA de inimigos e chefe; ADR-0005: RNG determinístico; ADR-0010: Resolução do combate no passo; ADR-0003: Entidades e portadores; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: A câmara 6 tem layout fixo e não consome `layout`/`ondas`/`spawn`/`elites`; o chefe é `InimigoRef` com flag e os lacaios entram na lista pela IA a pedido do chefe, teto de 9 inimigos; em Pactos a fase `Subjugado` deixa "em combate" falso e suspende a R9, e só `limpar_camara_chefe()` emite `camara_limpa(4, chefe)`, uma vez.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0001/ADR-0010)
**Engine Notes**: Nenhuma API pós-cutoff.

**Control Manifest Rules (Feature)**:
- Required: Câmaras são a única emissora de `camara_limpa`
- Forbidden: o chefe consumir fluxo estrutural

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-29 (substitui AC-CO-21): 4 pedras de 51 px em (390; 300), (1530; 300), (390; 750), (1530; 750); chefe em (960; 285) em `Surgindo`; fluxos `layout`, `ondas`, `spawn`, `elites` com 0 reais consumidos; `sortear_elite` não chamado.
- [x] AC-CO-30: Lâmina, golpe final no passo 640 → no passo 677 fase Limpa e `camara_limpa(4, chefe)` uma vez; nenhuma porta abre.
- [x] AC-CO-31 / AC-CO-32: Pactos, `chefe_subjugado` no passo 677 → fase `Subjugado`, "em combate" falso, R9 não roda, sem `camara_limpa`; `limpar_camara_chefe()` após `resolver_subjugado` → Limpa e `camara_limpa(4, chefe)` uma vez; segundo pedido ignorado.
- [x] AC-CO-33: `limpar_camara_chefe()` na fase Combate → nada muda e um erro de integração é registrado. TR-camaras-014: lacaios adicionados pela IA nunca levam a lista acima de 9.

---

## Implementation Notes

- O crédito de Fragmentos do chefe é dos Chefes (ver `production/epics/economia-de-fragmentos/story-006-credito-do-chefe.md`), antes do `camara_limpa`.

---

## Out of Scope

- Épico chefes: padrões, fases e Fúria
- Épico vinculo-e-pactos: escolha Pactuar/Exorcizar

---

## Files

- `src/gameplay/camaras/camaras.gd`
- `tests/unit/camaras/camara_do_chefe_test.gd`

Código atual da fatia: nenhum (a fatia não tem chefe).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/camara_do_chefe_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-007-ciclo-de-combate-e-limpar.md`; `production/epics/chefes/EPIC.md` e `production/epics/ia-de-inimigos-e-elites/EPIC.md` (stories a criar; dublês até lá)
- Unlocks: None
