# Story 006: Save: carga uma vez por sessão, catálogo Falhou e PerfilNulo

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-004, TR-save-005, TR-save-016
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md); [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md); [ADR-0004](../../../docs/architecture/adr-0004-catalogo-de-dados.md)
**ADR Decision Summary**: ConfigFile/FileAccess só em user:// por um adaptador ArmazemDeArquivos; gravação atômica com .bak; perfil.cfg com seção [vinculo] opaca; lógica pura acima do adaptador. O ADR-0015 fixa a carga depois do catálogo Pronto e antes da escolha de arma.
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

- [ ] **AC-SP-21 [L]** Catálogo em Falhou: ao iniciar a sessão e ocorrer um gatilho, zero leituras e zero gravações de perfil.cfg (modo Sem gravação).
- [ ] Carga acontece uma vez por sessão, depois do catálogo Pronto e antes da escolha de arma, em sequência pura sem SceneTree (TR-save-004).
- [ ] PerfilNulo (não lê, não grava) é injetável sem if no Save; o build de playtest lê e grava o perfil normalmente (TR-save-016).

---

## Implementation Notes

Classe Save (lógica pura) composta pelo Main (injeção via configurar()). Estados: Normal, Sem gravação. Da fatia, src/app/main.gd apenas passa a esperar a carga do Save antes da escolha de arma (adaptar na integração com o Main, fora desta story).

---

## Out of Scope

- story 007: gatilhos e gravação. story 008: sair e reset.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/save.gd, perfil_nulo.gd
- tests/unit/save/sequencia_de_carga_e_modo_sem_gravacao_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/sequencia_de_carga_e_modo_sem_gravacao_test.gd` — deve existir e passar

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: [story 004](story-004-carga-corrupcao-versao-e-migracao.md), [story 005](story-005-orfas-e-preservacao-de-chaves.md); production/epics/conteudo/EPIC.md (estado Pronto/Falhou do catálogo); production/epics/orquestrador-do-passo/EPIC.md (Main)
- Unlocks: stories 007, 008, 009

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Criados:** `src/foundation/persistencia/save.gd` (`Save`, estende `ConsumidorDeEventos`; `Save.Estado`: `NAO_CARREGADO`, `NORMAL`, `SEM_GRAVACAO`), `perfil_da_sessao.gd` (`@abstract PerfilDaSessao`: `carregar`, `modo`, `salvar`, `exportar_texto`, `importar_texto`, `resetar`), `perfil_nulo.gd` (`PerfilNulo`). `RepositorioDePerfil` passa a estender `PerfilDaSessao`. Teste: `tests/unit/save/sequencia_de_carga_e_modo_sem_gravacao_test.gd` — 7 casos, 7 passam.
- **AC cobertos:** AC-SP-21 (zero operações no armazém, zero `ler()`, zero avisos), carga uma vez por sessão (`carregar(catalogo_pronto)` só tem efeito na 1ª chamada), PerfilNulo pelo mesmo caminho do Save, repositório real lê e grava.
- **Decisões:** o Save recebe o estado do catálogo como `bool` em `carregar()` (catálogo Falhou → Sem gravação sem ler). Gatilho antes da carga fica pendente e `gravar_se_pendente` devolve `ERR_BUSY` (nunca grava sobre um arquivo não lido). `PerfilNulo` responde `NORMAL`, `salvar()=OK`, e chama `ler({})` se recebeu a porta. Interface `PerfilDaSessao` criada para o PerfilNulo ser injetável sem `if` (arquivo não previsto na story).
- **Pendências:** ligar no `src/app/main.gd` (fora do escopo: compor `Save`, chamar `carregar()` depois do catálogo e antes da escolha de arma).
