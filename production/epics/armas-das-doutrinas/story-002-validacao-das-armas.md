# Story 002: Validação das armas (AV1–AV9, V2, nomes canônicos)

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (Formulas › Faixas l.774, Validação l.830; R8; AC l.1520–1688, l.1798–1811)
**Requirement**: `TR-armas-008`, `TR-armas-009`, `TR-armas-010`, `TR-armas-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Validações cruzadas AV1–AV9 na segunda passada do catálogo, com relatório de conjunto exato; chave derivada `<chave_nome>_DESC` e nomes canônicos validados sem campo novo; AV9 aceita a forma `chamado` só no slot especial de `WeaponDef` de Pactos, com pares validados pelo ML8.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0004: protocolo SHA-256 (`HashingContext`) e `ResourceLoader.load` com cache — NEEDS VERIFICATION fora do caso mínimo.

**Control Manifest Rules (this layer)**:
- Forbidden: dimensões lidas de campos gravados no catálogo (Telégrafos derivam; aqui só validar)
- Required: validação na carga, erro bloqueia, aviso vai ao relatório

---

## Acceptance Criteria

- [x] AC-AR-23 [L] AV1 — guarda (l.1520)
- [x] AC-AR-24 [L] AV2 — paridade (l.1533)
- [x] AC-AR-25 [L] AV3 — pontos frágeis (informativo), conjunto exato (l.1548)
- [x] AC-AR-26 [L] AV4 — trava por golpe pesado (l.1571)
- [x] AC-AR-27 [L] AV5 — empurrão contínuo de Ataque leve sem combo (l.1591)
- [x] AC-AR-28 [L] AV6 — CV do Combate valem para arma (l.1603)
- [x] AC-AR-29 [L] AV7 — faixas de design (aviso) (l.1607)
- [x] AC-AR-30 [L] V2 — faixas de erro de carga (l.1634)
- [x] AC-AR-31 [L] AV8 — fração do Especial (l.1648)
- [x] AC-AR-32 [L] catálogo de fábrica — relatório completo, conjunto exato (l.1658)
- [x] AC-AR-33 [L] R8 — nomes canônicos (l.1673)
- [x] AC-AR-34 [L] R8 — "Corte" × Corte da esquiva (l.1680)
- [x] AC-AR-49 [L] AV3 com a Besta — conjunto exato (l.1798)
- [x] AC-AR-50 [L] AV9 e relatório de fábrica (l.1806)

---

## Implementation Notes

*Derived from ADR-0004:*

- Validador em duas passadas: campo a campo (V2) na carga, cruzado (AV1–AV9, CV do Combate via AV6, ML8 com Maldições) na segunda passada.
- Relatório com conjunto exato de erros/avisos (teste compara conjuntos, não contagem).
- **Código da fatia**: nenhum validador na fatia — construção do zero.

---

## Out of Scope

- Story 003: as fórmulas F1–F7 usadas por AV2/AV8 (este validador as chama)

---

## Files

- `src/content/validacao/validador_armas.gd`
- `tests/unit/weapons/validacao_armas_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/armas/validacao_armas_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-001-weapondef-e-armas-de-fabrica.md`, `production/epics/armas-das-doutrinas/story-003-formulas-de-referencia.md`, `production/epics/maldicoes/EPIC.md` (ML8)
- Unlocks: `production/epics/armas-das-doutrinas/story-004-arma-da-run-e-injecao.md`
