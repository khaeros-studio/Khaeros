# Story 006: Besta do Vínculo — Virote e Chamado

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (R2b; AC l.1753–1778)
**Requirement**: `TR-armas-012`, `TR-armas-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0017: Aliados e invocações; ADR-0002: Canal de eventos
**ADR Decision Summary**: O Especial `chamado` da Besta só pede o salto à Maldição pela consulta `pode_chamar`; a recusa não consome recarga e emite `chamado_indisponivel`; o Virote é golpe de arma sem hitstop e emite `acerto_virote` para a marca da Maldição.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0017: dublês com retorno tipado exigem `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required (Core): tudo por `player_id`; `MaldicaoRef` nunca destruído na Exaustão
- Forbidden (Core): a Maldição pedir hitstop ou escrever Vida de inimigo

---

## Acceptance Criteria

- [x] AC-AR-43 [I] R2b — Virote é golpe de arma sem hitstop (l.1753)
- [x] AC-AR-44 [L] R2b — evento `acerto_virote` e marca (l.1759)
- [x] AC-AR-45 [I] R2b — Chamado dispara o salto (l.1766)
- [x] AC-AR-46 [L] R2b — Chamado recusado não gasta recarga (l.1773)

---

## Implementation Notes

*Derived from ADR-0010 and ADR-0017:*

- Tudo vem do `AttackDef` (forma `chamado` no slot especial); o Combate consulta `pode_chamar(player_id)` no disparo do item 5 e só então desconta recarga.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- Épico `maldicoes`: o salto e a marca do lado da Maldição
- `combate-nucleo/story-009`: eventos `chamado`/`chamado_indisponivel` (definidos lá; aqui verificados com a Besta)

---

## Files

- `assets/data/armas/besta_do_vinculo.tres` (ajustes, se precisar)
- `tests/unit/weapons/besta_test.gd`
- `tests/integration/weapons/besta_chamado_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/armas/besta_e_dps_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-001-weapondef-e-armas-de-fabrica.md`, `production/epics/combate-nucleo/story-009-pactos-maldicao-acuada-e-chefe.md`, `production/epics/maldicoes/EPIC.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-008-verificacao-em-jogo.md` (o Fluxo do Virote, AC-SF-29, é testado por dublê em `selo-e-fluxo/story-002`)
