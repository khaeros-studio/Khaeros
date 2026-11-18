# Story 003: RepositorioDePerfil: formato, PortaDeSecao [vinculo] e texto determinístico

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-002, TR-save-003, TR-save-008
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md)
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

- [ ] **AC-SP-02 [L]** Vínculo dublê com escrever() = {especies:{vulto_mudo:{pactuada:true,vinculo_pontos:7,nivel:1,encontros_vistos:2}}, ultima_dupla:["vulto_mudo",""]}: ao gravar e carregar em nova instância, ler() recebe dicionário igual e o arquivo tem [meta] schema_version=1.
- [ ] **AC-SP-03 [L]** Gatilho sem mudança em escrever() → zero gravar_atomico no armazém (só grava se o texto mudou; igual conta como sucesso).
- [ ] **AC-SP-16 [L]** [vinculo] com float em especies → caso corrompido (.bak + aviso; ver story 004).
- [ ] **AC-SP-23 [L]** Mesmo escrever() gravado duas vezes dá textos idênticos byte a byte, sem user:// globalizado, letra de unidade nem nome do usuário.
- [ ] carregar() nunca falha (padrões em erro); salvar() -> Error; PortaDeSecao tem ler, escrever, campos_de_ids, migrar_conteudo; seções futuras seguem o mesmo contrato (TR-save-003).

---

## Implementation Notes

**Código atual da fatia**: nenhum cobre este módulo — construir do zero. Valores permitidos na seção: bool, int, String, Array/Dictionary desses; sem float, StringName, Object, Resource. Chaves ordenadas para determinismo. Se E-P3 mostrar que ConfigFile.parse/encode_to_text não fazem ida e volta, trocar por serializador INI próprio mínimo sem mudar a interface.

---

## Out of Scope

- story 004: carga, corrupção, versão futura, migração. story 005: órfãs e preservação.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/repositorio_de_perfil.gd, porta_de_secao.gd
- tests/unit/save/repositorio_de_perfil_formato_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/repositorio_de_perfil_formato_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (ver Completion Notes)

---

## Dependencies

- Depends on: [story 001](story-001-armazem-de-arquivos-e-caminhos.md)
- Unlocks: stories 004–009

---

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Criados:** `src/foundation/persistencia/repositorio_de_perfil.gd`, `porta_de_secao.gd` (`@abstract`: `escrever`, `ler`, `campos_de_ids`, `migrar_conteudo`), `modo_do_perfil.gd` (`ModoDoPerfil.Valor`: `NORMAL`, `SEM_GRAVACAO`). Testes: `tests/unit/save/repositorio_de_perfil_formato_test.gd` (11 casos) com dublê `tests/unit/save/vinculo_falso.gd` (preload, sem `class_name`). 11/11 passam.
- **AC cobertos:** AC-SP-02, 03, 16, 23; `carregar()` nunca falha, `salvar() -> Error`.
- **Decisões:** construtor `RepositorioDePerfil.new(armazem, caminhos, avisar: Callable, ids_de_especies: PackedStringArray, porta: PortaDeSecao, migracao: MigracaoDePerfil = null)`. **Avisos por `Callable`** em vez de `RelatorDeAvisos` (a classe ainda não existe e a Telemetria trabalha em paralelo: evitar colisão de `class_name`). **Catálogo como `PackedStringArray` de ids** (o `Main` extrai do catálogo Pronto; Falhou entra na story 006). `gravado_por` é propriedade injetada (padrão `""`). Após carga válida, o texto lido conta como "último gravado" (R5.2): só regrava se o texto canônico diferir. `escrever()` com tipo proibido → `ERR_INVALID_DATA`, nada gravado. Chaves ordenadas em todos os níveis.
- **Pendências:** `PERSIST_FALHA_GRAVAR` (aviso de falha de gravação, AC-SP-07) fica para a story 007 (o `salvar()` já devolve o `Error`); trocar o `Callable` por `RelatorDeAvisos` quando ele existir.
