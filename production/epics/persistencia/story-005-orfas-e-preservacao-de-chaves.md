# Story 005: Ids desconhecidos: órfãs, ultima_dupla e preservação de seções

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-012
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md); [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md)
**ADR Decision Summary**: ConfigFile/FileAccess só em user:// por um adaptador ArmazemDeArquivos; gravação atômica com .bak; perfil.cfg com seção [vinculo] opaca; lógica pura acima do adaptador. O catálogo (ADR-0004) fornece o conjunto de ids válidos.
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

- [ ] **AC-SP-13 [L]** especies de vulto_mudo e especie_teste_x com catálogo só de vulto_mudo: ler() não contém especie_teste_x; o arquivo regravado mantém a entrada com os mesmos valores.
- [ ] **AC-SP-14 [L]** ultima_dupla = ["especie_teste_x","vulto_mudo"] com a primeira fora do catálogo: ler() recebe ["","vulto_mudo"] (ids de campos_de_ids() viram vazio).
- [ ] **AC-SP-15 [L]** Arquivo com [oficina] nivel=3: após carregar e gravar, a seção volta igual (chaves e seções desconhecidas preservadas como texto).

---

## Implementation Notes

Entradas órfãs voltam ao arquivo e reaparecem quando um build com a espécie as lê. Preservar como texto mantém o determinismo byte a byte (story 003). O conjunto de ids vem do catálogo Pronto (épico conteudo); no teste, um dublê basta.

---

## Out of Scope

- Validação de conteúdo do Vínculo: épico vinculo-e-pactos.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/repositorio_de_perfil.gd (estende)
- tests/unit/save/orfas_e_preservacao_de_chaves_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/orfas_e_preservacao_de_chaves_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (ver Completion Notes)

---

## Dependencies

- Depends on: [story 004](story-004-carga-corrupcao-versao-e-migracao.md)
- Unlocks: None

---

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Estendido:** `src/foundation/persistencia/repositorio_de_perfil.gd`. Teste: `tests/unit/save/orfas_e_preservacao_de_chaves_test.gd` — 7 casos, 7 passam.
- **AC cobertos:** AC-SP-13 (órfã fora de `ler()` e regravada igual; reaparece num build com a espécie), AC-SP-14 (`ultima_dupla`; também `encontro_pendente`), AC-SP-15 (`[oficina] nivel=3` volta igual); determinismo mantido com preservação.
- **Decisões:** preservação por valor reinterpretado e regravado com chaves ordenadas (não por bytes brutos): a seção volta igual em conteúdo, e byte a byte quando já foi gravada por nós. Chave de primeiro nível de `[vinculo]` é "desconhecida" quando o arquivo a tem e `escrever()` não a devolve; `escrever()` vence em conflito; `especies` = órfãs ⊕ espécies de `escrever()`. Seções desconhecidas não são validadas por tipo (só `[meta]`/`[vinculo]` são do Save).
- **Pendências:** reset (story 008) deve descartar órfãs e seções preservadas — o estado fica em `_orfas`, `_vinculo_preservado`, `_secoes_preservadas`.
