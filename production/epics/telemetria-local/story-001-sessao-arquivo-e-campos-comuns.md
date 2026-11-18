# Story 001: Abertura da sessão, arquivo `.jsonl`, campos comuns e TelemetriaTuning

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R2, R3; § Tuning Knobs)
**Requirement**: `TR-telemetria-001`, `TR-telemetria-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP (§5); ADR-0004: Catálogo de dados
**ADR Decision Summary**: A Telemetria é `ConsumidorDeEventos` puro com a máquina de 6 estados do GDD; recebe `EscritorDeLinhas`, `ArmazemDeArquivos`, `RelogioDeSessao` (ms monotônico, µs, data UTC), `RelatorDeAvisos` e `TelemetriaTuning` validado. Arquivo novo por sessão em `user://telemetria/sessao-AAAAMMDD-HHMMSS[-N].jsonl`, handle aberto, `store_line` + descarga por linha.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0013: só `ArmazemUserGodot` toca `FileAccess`/`DirAccess`; o modo de anexar não é coberto pela referência (não usar). E-P1/E-P2 precisam ter rodado (bloqueio de produção do ADR-0013).

**Control Manifest Rules (Presentation)**:
- Required: Telemetria é `ConsumidorDeEventos` puro; conta bytes em memória e aplica R9 antes de escrever
- Forbidden: o jogo ler o `.jsonl`
- Guardrail: 1 ms por linha, 3 ms por passo (story 010)

---

## Acceptance Criteria

- [x] AC-TL-01 (R2): opção ligada → cria `sessao-AAAAMMDD-HHMMSS.jsonl` (UTC); linha 0 `sessao_iniciada` com `schema`, `versao`, `impressao` (4 hex), `os`, `data_utc`. (O valor de `schema` passa a 2 na story 009.)
- [x] AC-TL-02 (R3): toda linha tem `t`, `n` (0, 1, 2… sem buracos), `ms` não decrescente e `run`; `schema` só na linha 0.
- [x] AC-TL-03 (R2): o escritor falso recebe uma descarga depois de cada linha.
- [x] AC-TL-23 (R2): duas sessões no mesmo segundo → a segunda ganha `-2`.

---

## Implementation Notes

- `assets/data/tuning/telemetria_tuning.tres` (`max_bytes_sessao`, `max_sessoes`, reserva, orçamentos) validado pelo catálogo.
- Estados: Armada, Gravando, Desligada, Parada por falha, Encerrada (e o inicial do GDD).

---

## Out of Scope

- Eventos de jogo (006–009), falhas (004), limite e retenção (005).

---

## Files

- `src/presentation/telemetria/telemetria.gd`, `telemetria_tuning.gd`, `escritor_de_linhas.gd`, `relogio_de_sessao.gd`
- `assets/data/tuning/telemetria_tuning.tres`
- `tests/unit/telemetria/sessao_arquivo_e_campos_comuns_test.gd`

Código da fatia: nada reaproveitado. `src/app/main.gd` só ganha a composição quando o épico `run-e-regioes` criar a `ComposicaoDaSessao`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/sessao_arquivo_e_campos_comuns_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/sessao_arquivo_e_campos_comuns_test.gd`

---

## Dependencies

- Depends on: épicos `production/epics/persistencia/` (`ArmazemDeArquivos`, `opcoes.cfg`), `production/epics/conteudo/` (catálogo e impressão), `production/epics/experimentos-de-engine/` (EX-0013-P1/P4/P5)
- Unlocks: stories 002–010 deste épico
