# Story 010: Avisos PERFIL_* uma vez por sessão, só fora de Jogo, com foco duplo

> **Epic**: Save e perfil (persistência)
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-018
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md); [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md)
**ADR Decision Summary**: UI em Control sobre CanvasLayer com foco duplo (teclado e gamepad), escala 85–150%; avisos de persistência exibidos fora de JOGO.
**ADR Version**: 2026-11-16 (Last Verified; todos Accepted)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: UI/foco do 4.7 (ADR-0012, risco HIGH): conferir docs/engine-reference/godot/ antes de usar APIs de foco/AccessKit.

**Control Manifest Rules (this layer)**:
- Required: todo acesso a disco passa por ArmazemDeArquivos; .cfg só por gravar_atomico; todo bool/Error é verificado (ADR-0013)
- Forbidden: gravar .cfg durante um passo em JOGO; Autoload; ProjectSettings/OS fora do armazém real e do Main (ADR-0013, ADR-0001)
- Guardrail: carga dos .cfg uma vez na inicialização; gravação só por ação fora do passo (ADR-0013)

---

## Acceptance Criteria

*Do GDD `design/gdd/save-e-perfil.md`, recortados para esta story:*

- [ ] Cada aviso (PERFIL_CORROMPIDO, PERFIL_VERSAO_FUTURA, PERSIST_FALHA_GRAVAR, PERFIL_SAIR_SEM_SALVAR) aparece no máximo uma vez por sessão e só fora de Jogo.
- [ ] Navegável por teclado e gamepad, sem mouse; escala 85–150% sem cortar texto.
- [ ] Screenshot retido de cada aviso/tela tocada em production/qa/evidence/.

---

## Implementation Notes

O Save publica os avisos como dados (código + parâmetros); a tela só os apresenta. Textos por chave de tradução, nunca literais. Sem estado de jogo próprio: respeitar pedir_estado.

---

## Out of Scope

- Lógica de quando emitir os avisos: stories 004, 007, 008.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/presentation/ui/avisos_do_perfil.gd (+ cena em scenes/ui/)
- production/qa/evidence/save-avisos-do-perfil-*.png

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- Config/Data: smoke check em `production/qa/smoke-*.md`

**Status**: [ ] Modelo testado; tela e screenshot pendentes

---

## Dependencies

- Depends on: [story 007](story-007-gatilhos-pendente-e-ponto-seguro.md), [story 008](story-008-sair-e-reset.md); production/epics/hud/EPIC.md (base de UI/foco)
- Unlocks: None

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Criados:** `src/foundation/persistencia/fila_de_avisos_do_perfil.gd` (`FilaDeAvisosDoPerfil`: modelo puro; `receber(chave)` é o `Callable` de avisos do Save e do repositório; `atual(estado_de_jogo)`; `escolher(acao)`). Teste: `tests/unit/save/fila_de_avisos_do_perfil_test.gd` — 6 casos, 6 passam.
- **Coberto:** cada aviso (`PERFIL_CORROMPIDO`, `PERFIL_VERSAO_FUTURA`, `PERSIST_FALHA_GRAVAR`, `PERFIL_SAIR_SEM_SALVAR`) entra no máximo uma vez por sessão e nunca aparece em JOGO; ações com chave de tradução, ação padrão (foco) e ação de `ui_voltar` definidas.
- **Decisões:** o modelo fica em Foundation/persistencia (sem Control) porque não há base de UI/foco para pendurar a tela; `PERFIL_SAIR_SEM_SALVAR` fura a fila; nele padrão e voltar = "Tentar de novo" (toque acidental não descarta progresso); "Tentar de novo" mantém o aviso aberto; `PERSIST_FALHA_GRAVAR` marcado `discreto`.
- **Pendências reais:** (1) apresentação `src/presentation/ui/avisos_do_perfil.gd` + cena em `scenes/ui/` (Control em CanvasLayer, foco duplo, escala 85–150%) — depende do épico hud (base de UI/foco, ADR-0012); (2) chaves de tradução `AVISO_ACAO_OK`, `PERFIL_ACAO_TENTAR_DE_NOVO`, `PERFIL_ACAO_SAIR_SEM_SALVAR` e os textos das 4 chaves na tabela de tradução; (3) **evidência pendente: precisa de execução com janela** — nenhum screenshot em `production/qa/evidence/` (não há tela).
