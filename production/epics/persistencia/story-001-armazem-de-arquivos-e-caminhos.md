# Story 001: ArmazemDeArquivos, ArmazemEmMemoria e CaminhosDePersistencia

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-001, TR-save-017
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md); [ADR-0001](../../../docs/architecture/adr-0001-orquestrador-do-passo.md)
**ADR Decision Summary**: ConfigFile/FileAccess só em user:// por um adaptador ArmazemDeArquivos; gravação atômica com .bak; perfil.cfg com seção [vinculo] opaca; lógica pura acima do adaptador.
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

- [ ] ArmazemDeArquivos (@abstract, RefCounted) e ArmazemEmMemoria (mapa caminho→bytes, registro de leituras/gravações/cópias, falhas programáveis por operação e ordem: programar_falha(&"gravar_atomico", 1)) existem e rodam sem SceneTree (TR-save-017).
- [ ] CaminhosDePersistencia.de(0) devolve user://perfil.cfg e os demais caminhos do ADR-0013 §2 (TR-save-001); perfil ≠ 0 é rejeitado com diagnóstico.
- [ ] Nenhum Autoload; módulos recebem o armazém por injeção; só a thread principal acessa o armazém.
- [ ] Contrato coberto por teste: ler, gravar_atomico, copiar_bytes, existe, listar; falha programada devolve Error e não altera o mapa.

---

## Implementation Notes

**Código atual da fatia**: nenhum cobre este módulo — construir do zero. Interface do ADR-0013 §1. ArmazemUserGodot fica na story 002. O dublê é a base dos AC [L] de todo o épico (AC-SP-01..23).

---

## Out of Scope

- [story 002](story-002-armazem-user-godot-gravacao-atomica.md): implementação real sobre FileAccess/DirAccess.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/armazem_de_arquivos.gd, armazem_em_memoria.gd, caminhos_de_persistencia.gd
- tests/unit/save/armazem_de_arquivos_e_caminhos_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/armazem_de_arquivos_e_caminhos_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (ver Completion Notes)

---

## Dependencies

- Depends on: None (só o contrato de injeção do Main em production/epics/orquestrador-do-passo/EPIC.md)
- Unlocks: stories 002–010 deste épico

---

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Criados:** `src/foundation/persistencia/armazem_de_arquivos.gd` (`@abstract`), `armazem_em_memoria.gd`, `caminhos_de_persistencia.gd`; e, por serem tipos da interface do ADR-0013 §1 que o contrato exige, `leitura_de_arquivo.gd` (`LeituraDeArquivo`) e `escritor_de_linhas.gd` (`EscritorDeLinhas`, `@abstract`). Teste: `tests/unit/save/armazem_de_arquivos_e_caminhos_test.gd`.
- **Testes:** 17 casos, 17 passaram, 0 erros/órfãos (gdUnit4 6.2.3, headless).
- **Decisões:** `programar_falha(op, ordem)` com ordem 1-based e `SEMPRE` (0) para toda chamada; falha não altera o mapa. O registro inclui `existe` (necessário para AC-SP-18 "nenhuma operação"). `copiar_bytes` nunca sobrescreve (`ERR_ALREADY_EXISTS`), reforçando "nunca apaga backup". `CaminhosDePersistencia.de(n≠0)` devolve instância com `valido=false` e `diagnostico` (sem `push_error`, para não poluir o log de teste). Caminhos são lógicos (`user://…`); a raiz física é do armazém real. Dicionários sem tipo (dicionário tipado não está coberto em `docs/engine-reference/`).
- **Pendências:** nenhuma.
