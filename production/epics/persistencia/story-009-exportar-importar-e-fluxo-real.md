# Story 009: exportar_texto/importar_texto e fluxo real em raiz temporária

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-015
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md)
**ADR Decision Summary**: ConfigFile/FileAccess só em user:// por um adaptador ArmazemDeArquivos; gravação atômica com .bak; perfil.cfg com seção [vinculo] opaca; lógica pura acima do adaptador. exportar_texto()/importar_texto() são portas de texto sem tela no MVP.
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

- [ ] **AC-SP-22 [L]** exportar_texto() de um perfil A e importar_texto() em outro Save: ler() recebe o mesmo dicionário; texto corrompido devolve erro ≠ OK e não altera o estado (mesma validação da carga).
- [ ] **AC-SP-25 [I]** Raiz temporária: perfil ausente, uma sessão faz um pacto (dublê), fecha; a segunda sessão carrega e a espécie aparece como pactuada.

---

## Implementation Notes

Fragmentos e RNG não entram no export (ADR-0013 §6/§7). O teste [I] usa ArmazemUserGodot real e depende de EX-0013; o caso AC-SP-22 roda em memória e pode ser feito antes.

---

## Out of Scope

- Qualquer tela de exportar/importar (fora do MVP).

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/save.gd (estende)
- tests/unit/save/exportar_importar_test.gd
- tests/integration/save/exportar_importar_e_fluxo_real_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/exportar_importar_e_fluxo_real_test.gd` ou documento de playtest

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: [story 002](story-002-armazem-user-godot-gravacao-atomica.md), [story 006](story-006-sequencia-de-carga-e-modo-sem-gravacao.md), [story 007](story-007-gatilhos-pendente-e-ponto-seguro.md)
- Unlocks: None

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Estendidos:** `repositorio_de_perfil.gd` (`exportar_texto`, `importar_texto`: mesma `_processar_texto` da carga; corrompido → `ERR_PARSE_ERROR`, versão futura → `ERR_FILE_UNRECOGNIZED`, erro não muda porta nem preservação), `save.gd` (repasse; importar OK marca pendente). Testes: `tests/unit/save/exportar_importar_test.gd` (2 casos) e `tests/integration/save/exportar_importar_e_fluxo_real_test.gd` (1 caso [I], `ArmazemUserGodot` em `user://_testes/fluxo_real_perfil/`, apagado ao fim). 3/3 passam.
- **AC cobertos:** AC-SP-22, AC-SP-25.
- **Decisões:** o export inclui órfãs e seções preservadas (é o texto do perfil); importar não emite aviso nem grava. Fragmentos e RNG não entram (o Save não os conhece).
- **Pendências:** o [I] roda no editor headless; a confirmação no build exportado segue com EX-0013 (story 005 de experimentos-de-engine).
