# Story 007: Gatilhos de gravação, pendente coalescido e ponto seguro

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-006, TR-save-007, TR-save-010
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md); [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md); [ADR-0001](../../../docs/architecture/adr-0001-orquestrador-do-passo.md); [ADR-0015](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md)
**ADR Decision Summary**: Gatilhos só marcam o perfil pendente; o Main grava no fim de passo fora de JOGO; vários gatilhos viram uma gravação.
**ADR Version**: 2026-11-16 (Last Verified; todos Accepted)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ConfigFile.parse/encode_to_text e DirAccess.rename sobre destino existente no Windows são incertos (E-P2, E-P3 em EX-0013, ainda não executados); ver production/epics/experimentos-de-engine/EPIC.md. Não usar como fato antes do experimento.

**Control Manifest Rules (this layer)**:
- Required: todo acesso a disco passa por ArmazemDeArquivos; .cfg só por gravar_atomico; todo bool/Error é verificado (ADR-0013)
- Forbidden: gravar .cfg durante um passo em JOGO; Autoload; ProjectSettings/OS fora do armazém real e do Main (ADR-0013, ADR-0001)
- Guardrail: carga dos .cfg uma vez na inicialização; gravação só por ação fora do passo (ADR-0013)

---

## Acceptance Criteria

*Do GDD `design/gdd/save-e-perfil.md`, recortados para esta story:*

- [ ] **AC-SP-04 [L]** Estado Jogo e pacto_registrado no passo n; passos n..n+5 em Jogo e n+6 em Transição: zero gravações até o fim de n+5 e exatamente uma no fim de n+6, nunca durante o processamento de um passo.
- [ ] **AC-SP-05 [L]** Três gatilhos (pacto, dupla, pacto) antes de um ponto seguro: uma gravação, com o estado do último gatilho.
- [ ] **AC-SP-06 [L]** run_encerrada(derrota) e depois run_encerrada(vitória) em outra run: cada uma produz uma gravação no ponto seguro seguinte.
- [ ] **AC-SP-07 [L]** programar_falha(&"gravar_atomico", 1), dois gatilhos em pontos seguros diferentes: o 1º devolve erro e emite PERSIST_FALHA_GRAVAR uma vez, estado em memória inalterado; o 2º grava sem novo aviso (sem laço de nova tentativa).
- [ ] Gatilhos reconhecidos: pacto_registrado, run_encerrada (vitória, derrota, abandono), Sair, reset, dupla escolhida (TR-save-006).

---

## Implementation Notes

O Save consome eventos do passo pelo canal (ADR-0002) só para marcar pendente; a gravação roda no fim de passo em PAUSA, BÊNÇÃO (inclui a tela de consentimento do pacto), MENUS, MORTE ou TRANSIÇÃO — nunca no meio da lista de eventos. Ponto seguro exposto ao Main como gravar_se_pendente(), chamado fora de JOGO.

---

## Out of Scope

- story 008: Sair/reset. story 010: exibição dos avisos.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/save.gd (estende)
- tests/unit/save/gatilhos_pendente_e_ponto_seguro_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/gatilhos_pendente_e_ponto_seguro_test.gd` — deve existir e passar

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: [story 006](story-006-sequencia-de-carga-e-modo-sem-gravacao.md); production/epics/orquestrador-do-passo/EPIC.md (canal de eventos e fim de passo)
- Unlocks: stories 008, 010

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Estendido:** `src/foundation/persistencia/save.gd` (`consumir`, `marcar_pendente`, `pendente`, `gravar_se_pendente(estado_de_jogo)`). Teste: `tests/unit/save/gatilhos_pendente_e_ponto_seguro_test.gd` — 8 casos, 8 passam.
- **AC cobertos:** AC-SP-04, 05, 06, 07; gatilhos `pacto_registrado`, `run_encerrada`, `dupla_confirmada` por `tipo()` do evento (Sair e reset são chamadas diretas, story 008).
- **Decisões:** estados seguros = MENU, PAUSA, BENCAO, TRANSICAO, MORTE (JOGO e INICIANDO → `ERR_BUSY`, pendente mantido). Em falha o pendente é descartado (sem laço; o próximo gatilho tenta), `PERSIST_FALHA_GRAVAR` uma vez por sessão; Sem gravação descarta o pendente com `ERR_UNAVAILABLE`. As classes de evento ainda não existem no código: o Save compara só a `StringName` (`Save.EV_*`).
- **Pendências:** o `Main` chamar `save.consumir(eventos)` e `save.gravar_se_pendente(estado)` no fim do passo, depois da entrega (ADR-0015 define o ponto); os eventos tipados (`EvPactoRegistrado` etc.) devem usar esses `TIPO`.
