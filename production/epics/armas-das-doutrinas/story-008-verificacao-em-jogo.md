# Story 008: Silhueta das armas e verificação em jogo

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (R3, R6, Visual/Audio l.1075, Game Feel l.1107; AC l.1368, l.1689, l.1717–1741, l.1817)
**Requirement**: `TR-armas-002`, `TR-armas-010` (verificação em run)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0004: Catálogo de dados
**ADR Decision Summary**: A arma é só dados; a forma desenhada é a do teste de acerto; o DPS medido em run confere com o calculado pelo validador.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Depende da Apresentação (ADR-0011, HIGH) para o desenho das formas.

**Control Manifest Rules (this layer)**:
- Required: a vista sai da mesma geometria do teste (`GeometriaDeAcerto`)

---

## Acceptance Criteria

- [x] AC-AR-13 [V] R3 — silhueta das armas (l.1368)
- [x] AC-AR-35 [I] F1 — DPS medido em run, por arma (l.1689)
- [x] AC-AR-37 [M] R6 — escolha de arma (l.1717)
- [x] AC-AR-38 [M] R6 — vitória por câmara (l.1721)
- [x] AC-AR-52 [M] R3/Game Feel — leitura da dupla (l.1817)

---

## Implementation Notes

*Derived from ADR-0010:*

- Sem código novo de regra; mede e registra. AC-AR-35 automatizada em `tests/integration/weapons/`; as [M] com testador, build e resultado registrados.

---

## Out of Scope

- Ajuste de números (volta ao `game-designer` se a medição divergir)

---

## Files

- `tests/integration/weapons/dps_medido_test.gd`
- `production/qa/evidence/armas-silhueta-*.png`
- `production/qa/evidence/armas-verificacao-em-jogo-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidos + assinatura do lead em `production/qa/evidence/armas-doutrinas-evidence.md`; `tests/unit/armas/besta_e_dps_test.gd`

**Status**: [x] Verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-004-arma-da-run-e-injecao.md`, `production/epics/armas-das-doutrinas/story-006-besta-virote-e-chamado.md`, `production/epics/armas-das-doutrinas/story-007-tela-de-escolha-de-arma.md`, `production/epics/combate-nucleo/story-010-leitura-visual-desempenho-e-latencia.md`
- Unlocks: None
