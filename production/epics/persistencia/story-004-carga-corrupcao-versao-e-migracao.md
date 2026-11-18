# Story 004: Carga: arquivo ausente, corrompido (.bak), versão futura e migração

> **Epic**: Save e perfil (persistência)
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-009, TR-save-011
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

- [ ] **AC-SP-01 [L]** Armazém vazio: ler({}) uma vez, zero gravações, zero avisos, estado Normal.
- [ ] **AC-SP-08 [L]** perfil.cfg com %%lixo: perfil.cfg.bak idêntico ao original, ler({}), um PERFIL_CORROMPIDO; o próximo gatilho substitui perfil.cfg.
- [ ] **AC-SP-09 [L]** .bak já existe: cópia vai para .bak2, .bak intacto (nunca apaga backup).
- [ ] **AC-SP-10 [L]** Cópia falha (copiar_bytes): estado Sem gravação, zero gravar_atomico, arquivo com bytes originais.
- [ ] **AC-SP-11 [L]** schema_version=2 num Save que suporta 1: ler({}), um PERFIL_VERSAO_FUTURA, zero gravações, arquivo byte a byte igual.
- [ ] **AC-SP-12 [L]** Fixture sem schema_version (ausente = 1) e cadeia de teste migrar(1→2): tratado como 1, ler() recebe o dado migrado, a carga não grava.
- [ ] **AC-SP-17 [L]** especies.vulto_mudo.nivel = "dois" (texto) com o resto válido: não é corrompido (zero .bak); ler() recebe a entrada para o Vínculo validar.

---

## Implementation Notes

Ordem da carga (ADR-0013 §7): ler → recuperação de sobras (.tmp/.old) → interpretar → versão → validar forma fina ([meta], existência e tipo de especies, tipos permitidos) → migrar → filtrar ids → ler(). Migrações de conteúdo pertencem ao dono da seção (migrar_conteudo). Faixas e níveis são validados pelo Vínculo, não aqui.

---

## Out of Scope

- story 005: ids desconhecidos. story 006: quando a carga acontece na sessão.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/repositorio_de_perfil.gd (estende), migracao_de_perfil.gd
- tests/unit/save/carga_corrupcao_versao_e_migracao_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/carga_corrupcao_versao_e_migracao_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (ver Completion Notes)

---

## Dependencies

- Depends on: [story 003](story-003-repositorio-de-perfil-formato.md)
- Unlocks: stories 006, 008

---

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Criados/estendidos:** `src/foundation/persistencia/migracao_de_perfil.gd` (cadeia pura `registrar(v_de, Callable)`, `pode_migrar`, `migrar`; `VERSAO_DO_MVP = 1`), `repositorio_de_perfil.gd` (carga). Teste: `tests/unit/save/carga_corrupcao_versao_e_migracao_test.gd` — 14 casos, 14 passam.
- **AC cobertos:** AC-SP-01, 08, 09 (+ `.bak3`), 10, 11, 12, 17; mais os Edge Cases de forma (vazio, só espaços, `schema_version` texto/0/negativo, `especies` não-`Dictionary`, `[vinculo]` sem `especies`, `StringName`, `gravado_por` não-texto, chave fora de seção) e leitura que falha.
- **Decisões:** por E-P3, texto sem nenhuma seção (ex.: `%%lixo`) ou com chaves fora de seção = corrompido. Arquivo existente que não pôde ser lido = corrompido (tenta `.bak`). Cadeia de migração incompleta = corrompido (com `.bak`). `migrar_conteudo(v_de, dados)` do dono recebe a versão de formato do arquivo e roda depois da migração de formato, antes do filtro de ids. `PERFIL_CORROMPIDO` sai também quando a cópia falha (o GDD manda o aviso "uma vez" no caso corrompido). Aviso no máximo uma vez por sessão por chave.
- **Pendências:** nenhuma desta story.
