# Story 005: Limite de bytes com reserva, retenção de 20 sessões e linha truncada

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R9, R10, F3, F5)
**Requirement**: `TR-telemetria-008`, `TR-telemetria-001` (última linha pode ficar truncada)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP
**ADR Decision Summary**: Bytes contados em memória e R9 aplicada antes de escrever (reserva de 512 B para `sessao_encerrada`); retenção das últimas `max_sessoes` (20) ao iniciar, só sobre `sessao-*.jsonl`; arquivo truncado é tolerado pelo leitor.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: Listagem e remoção pelo `ArmazemDeArquivos`.

**Control Manifest Rules (Presentation)**:
- Required: contar bytes em memória e aplicar R9 antes de escrever
- Forbidden: apagar arquivo que não seja `sessao-*.jsonl`
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-20 (R9, F3): `max_bytes_sessao` = 4 KB → a última linha de dados cabe com a reserva de 512 B, `sessao_encerrada` (`limite`) é a última e o arquivo final é ≤ 4 096 B; nenhuma linha depois.
- [x] AC-TL-21 (R9, F5): com 20 arquivos e `max_sessoes` 20 → apaga 1 (o mais antigo); com 12, nenhum; `outro.txt` nunca é apagado.
- [x] AC-TL-22 (R10): última linha cortada → o leitor de teste ignora só essa e lê as demais; sem `sessao_encerrada` = sessão abrupta.

---

## Implementation Notes

- O leitor de teste vive em `tests/` (nunca em `src/`, por AC-TL-30).

---

## Out of Scope

- Apagar dados por pedido do jogador: story 003.

---

## Files

- `src/presentation/telemetria/telemetria.gd`, `retencao_de_sessoes.gd`
- `tests/unit/telemetria/limite_retencao_e_truncamento_test.gd`, `tests/unit/telemetria/leitor_de_teste.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/limite_retencao_e_truncamento_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/limite_retencao_e_truncamento_test.gd` e `tests/unit/telemetria/leitor_de_teste.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-001-sessao-arquivo-e-campos-comuns.md`
- Unlocks: `production/epics/telemetria-local/story-010-run-completa-e-pior-passo.md`
