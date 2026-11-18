# Story 008: Sair/fechar janela com gravação e reset com duas confirmações

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-013, TR-save-014
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md); [ADR-0015](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md); [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md)
**ADR Decision Summary**: Sair no meio da run é abandono: o Save grava antes de sair; reset só no menu principal, com cópia .reset.bak e cancelamento se a cópia falhar.
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

- [ ] **AC-SP-20 [L]** Run ativa com escrever() diferente do último gravado, jogador escolhe Sair: uma gravação antes do fim; com falha programada aparece PERFIL_SAIR_SEM_SALVAR e "Tentar de novo" faz exatamente mais uma tentativa.
- [ ] Fechar a janela é interceptado, consolida abandono (Vínculo) e grava antes de sair (TR-save-013).
- [ ] **AC-SP-18 [L]** Reset no menu principal com perfil de pactos e uma órfã, duas confirmações: perfil.cfg.reset.bak igual ao anterior, ler({}), perfil novo gravado sem órfã; opcoes.cfg, preferencias.cfg e input_binds.cfg sem nenhuma operação no registro do armazém.
- [ ] **AC-SP-19 [L]** Falha programada em copiar_bytes: reset cancelado, zero gravar_atomico, ler() não chamado. Reset indisponível em Sem gravação.

---

## Implementation Notes

**Código atual da fatia**: nenhum cobre este módulo — construir do zero. A interceptação de NOTIFICATION_WM_CLOSE_REQUEST fica no Main (adaptar src/app/main.gd na integração); esta story entrega a lógica pura (pedir_saida(), reset(confirmacoes)). As telas de confirmação ficam com o épico hud (ADR-0012), com foco por teclado e gamepad.

---

## Out of Scope

- Telas de confirmação e do aviso de saída: épico hud. Exibição geral dos avisos: story 010.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/save.gd (estende)
- tests/unit/save/sair_e_reset_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/sair_e_reset_test.gd` — deve existir e passar

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: [story 004](story-004-carga-corrupcao-versao-e-migracao.md), [story 007](story-007-gatilhos-pendente-e-ponto-seguro.md)
- Unlocks: story 010

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Estendidos:** `save.gd` (`pedir_saida(consolidar_abandono)`, `tentar_saida_de_novo`, `reset_disponivel`, `resetar(confirmacoes)`), `repositorio_de_perfil.gd` (`resetar()`: cópia `.reset.bak`/`.reset.bakN`, descarta órfãs/seções preservadas, `ler({})`). Teste: `tests/unit/save/sair_e_reset_test.gd` — 8 casos, 8 passam.
- **AC cobertos:** AC-SP-20 (sucesso; falha → `PERFIL_SAIR_SEM_SALVAR` uma vez e "Tentar de novo" = exatamente mais um `gravar_atomico`), consolidação de abandono antes da gravação, AC-SP-18 (incluindo zero operações em `opcoes.cfg`, `preferencias.cfg`, `input_binds.cfg`), AC-SP-19 (+ indisponível em Sem gravação; uma confirmação → `ERR_UNAUTHORIZED`).
- **Decisões:** `pedir_saida` grava na hora (o Main chama fora do passo, não haverá passo seguinte); o reset só marca pendente, conforme ADR-0013 §7 (os gatilhos, inclusive reset, só marcam o perfil pendente), e grava no próximo ponto seguro (no menu, o fim do mesmo passo). Perfil ausente no reset: sem cópia, segue. Em Sem gravação/antes da carga, `pedir_saida` devolve OK (nada a gravar).
- **Pendências:** interceptar `NOTIFICATION_WM_CLOSE_REQUEST` no `Main` (depende de E-P7); telas de confirmação do reset e de saída: épico hud.
