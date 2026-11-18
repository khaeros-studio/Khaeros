# Story 003: Opção `telemetria_ligada` (Armada/Desligada) e "Apagar dados"

> **Epic**: Telemetria local
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telemetria-local.md` (R6, R9)
**Requirement**: `TR-telemetria-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP
**ADR Decision Summary**: `opcoes.cfg [telemetria] ligada` (padrão `true`) fica fora de `preferencias.cfg`; estados Armada/Desligada; "Apagar dados" apaga só `sessao-*.jsonl`, depois da confirmação, sem tocar o arquivo da sessão em curso.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: Apagar e listar via `ArmazemDeArquivos`; dublê em memória com falha injetável.

**Control Manifest Rules (Presentation)**:
- Required: o Feedback/UI pede ao dono da opção (não aplica diretamente)
- Forbidden: o jogo ler o `.jsonl`
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TL-15 (R6): com `telemetria_ligada` falso, nenhum arquivo é criado nem aberto na sessão inteira.
- [x] AC-TL-16 (R6): desligar com a run em curso → `sessao_encerrada` (`desligada`) e o arquivo fecha; ligar → Armada; a próxima `run_iniciada` abre arquivo novo com `sessao_iniciada` (`n = 0`) e `run` continua a contagem; após Parada por falha, ligar não abre arquivo.
- [x] AC-TL-26 (R6): "Apagar dados" apaga só `sessao-*.jsonl`, depois da confirmação, e não apaga o arquivo da sessão em curso.
- [x] AC-TL-32 (R6, R9): arquivo que não pode ser apagado é ignorado com `TL1` e a gravação segue.

---

## Implementation Notes

- A tela de opções (item telemetria, abrir pasta, apagar dados) é do ADR-0012 / épico `hud`; aqui só a API: `definir_ligada(bool)`, `apagar_dados()`.

---

## Out of Scope

- UI do item de opções: épico `production/epics/hud/`.

---

## Files

- `src/presentation/telemetria/telemetria.gd`
- `tests/unit/telemetria/opcao_ligada_e_apagar_dados_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telemetria/opcao_ligada_e_apagar_dados_test.gd` — must exist and pass
**Status**: [x] Complete — `tests/unit/telemetria/opcao_ligada_e_apagar_dados_test.gd`

---

## Dependencies

- Depends on: `production/epics/telemetria-local/story-001-sessao-arquivo-e-campos-comuns.md`; épico `production/epics/persistencia/` (`RepositorioDeOpcoes`)
- Unlocks: None
