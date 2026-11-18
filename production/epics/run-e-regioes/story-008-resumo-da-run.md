# Story 008: ResumoDaRun imutável (12 campos) e duração em passos

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R7, R7-P; F2, F3)
**Requirement**: `TR-run-007`, `TR-run-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§8); ADR-0001; ADR-0002
**ADR Decision Summary**: `ResumoDaRun` montado uma vez em `_encerrar(motivo)`, campos fixados no `_init`, só getters, arrays duplicados com `make_read_only()`; 10 campos da R7 + `desfecho_chefe` e `dupla`; `total` derivado. Duração = passos de Jogo (`passos_em_jogo()`, contando hitstop) / 60.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: `Array.make_read_only()` (Godot 4.x) — confirmar em 4.7.2 que mutar um array read-only falha (erro), não muda em silêncio.

**Control Manifest Rules (this layer)**:
- Required: `ResumoDaRun` sem setters; arrays com `make_read_only()` (ADR-0015)
- Required: `passos_em_jogo()` nunca zera na run (ADR-0001)

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-37** O resumo tem 12 campos; `chefe_escolhido` fora da câmara 6 é ignorado; não muda depois de montado.
- [x] **AC-RN-18 (parte vigente)** Uma vitória dá câmaras limpas = 7; uma morte depois de limpar os índices 0 a 3 dá 4.
- [x] **AC-RN-23** Os três exemplos da F2 (22, 7, 4); 3 600 passos, contando os de hitstop, dão 60 s.

---

## Implementation Notes

*Derived from ADR-0015 §8 (assinatura do `_init` no ADR):*

- Teste: mutar o array devolvido não altera o resumo; não há setter (reflexão sobre a lista de métodos).

---

## Out of Scope

- Story 009: a tela final que lê o resumo.
- Épico `telemetria-local`: gravação do resumo.

---

## Files

- `src/gameplay/run/resumo_da_run.gd`
- `tests/unit/run/run_resumo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/run/run_resumo_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-001-maquina-de-estados-da-run.md`
- Unlocks: `production/epics/run-e-regioes/story-006-vitoria.md`, `production/epics/run-e-regioes/story-007-morte-abandono-e-pausa.md`

**Código da fatia**: `kills`/tempo da fatia em `game_session.gd` — **substituir**.
