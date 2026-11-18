# Story 009: Recarga de debug, revogação de ajustes e tela de erros

> **Epic**: conteudo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R9 Recarga, UI Requirements, States and Transitions)
**Requirement**: `TR-conteudo-012` (estados de carga e recarga só em debug e fora de run, com revogação e reinjeção)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0001, ADR-0012)
**ADR Decision Summary**: Recarga em release ou durante run é recusada; ao sair de Pronto o carregador revoga o catálogo e injeta ajustes vazios nos seis consumidores persistentes (Input, câmera, HUD, Tela de bênção, Feedback, Pipeline); candidato novo é lido com `CACHE_MODE_IGNORE_DEEP`; sucesso recalcula a impressão e reinjeta; falha descarta o candidato e deixa os consumidores sem ajustes; a tela de erros usa só entradas digitais (Input R12).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `ResourceLoader.load(..., CACHE_MODE_IGNORE_DEEP)` com manifesto e sub-recursos externos (EX-0004-NV).

**Control Manifest Rules (this layer)**:
- Required: carregador recebe o estado da run por interface; sistemas de run recebem o catálogo só na construção da run; estado `Falhou` bloqueia a run e leva ao modo Sem gravação (ADR-0013).
- Forbidden: recarga em release ou durante run; consumidor lendo ajustes de catálogo revogado.
- Guardrail: tela de erros legível e navegável sem analógico.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-05: com estado de run injetado "em run", a recarga é recusada com aviso e o catálogo não muda; "fora de run" vai para Carregando.
- [x] AC-06: recarga cujo conteúdo falha leva a Falhou e o catálogo anterior deixa de ser acessível.
- [x] AC-07 (UI): catálogo com 2 erros e 1 aviso: a tela lista os 3 itens com arquivo, campo, regra e valor, o aviso marcado como aviso, e não há como iniciar uma run. Screenshot retido.
- [x] AC-47: com catálogo Pronto de pasta temporária, editar um valor de um `.tres` e recarregar fora de run: o catálogo novo tem o valor novo (sem cache), a impressão mudou, uma run criada depois recebe o valor novo, e um consumidor falso fora da run recebeu o `InputTuning` novo ao entrar em Pronto.
- [x] AC-51: catálogo que termina em Falhou (inclusive `zm + ze ≥ 1` no `InputTuning`): nenhum sistema fora da run recebeu Tuning; a lista rola e Copiar relatório e Sair são acionados só por D-pad e botões do gamepad; o analógico não move o foco; partindo de Pronto, uma recarga que falha deixa o consumidor falso sem Tuning.

---

## Implementation Notes

Estender o carregador (story 003) com `recarregar()` e a lista de consumidores a reinjetar (interface `ConsumidorDeAjustes`). A tela é um `Control` em `CanvasLayer` (ADR-0012), focável pelos botões; strings por chave de tradução. "Copiar relatório" usa `PortaDaAreaDeTransferencia` (EX-0012-CB).

**Código atual**: `src/presentation/game_hud.gd` não tem tela de erros: nova cena `src/presentation/tela_de_erros_do_catalogo.gd`; reaproveitar apenas o padrão de `Control` do HUD existente.

---

## Out of Scope

- Conteúdo dos relatórios dos donos (story 006); remapeamento (épico `input`).

---

## Files

- `src/content/carregador_de_catalogo.gd` (recarga), `consumidor_de_ajustes.gd`
- `src/presentation/tela_de_erros_do_catalogo.gd`
- `tests/unit/content/recarga_test.gd`, `tests/integration/content/recarga_e_falha_test.gd`
- `production/qa/evidence/conteudo-tela-de-erros.png`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshot retido da tela de erros (`production/qa/evidence/conteudo-tela-de-erros.png`) + testes acima, must exist and pass.

**Status**: [x] Created (`production/qa/evidence/conteudo-tela-de-erros.png` e `conteudo-carga-do-catalogo.md`)

---

## Dependencies

- Depends on: `story-003-carregador-e-manifesto.md`, `story-008-impressao-canonica.md`, `production/epics/experimentos-de-engine/story-002-catalogo-e-cena.md`, `production/epics/experimentos-de-engine/story-008-ui-offset-ui-actions-clipboard.md`
- Unlocks: épicos `input`, `hud`, `persistencia` (modo Sem gravação)
