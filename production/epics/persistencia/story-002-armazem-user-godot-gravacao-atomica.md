# Story 002: ArmazemUserGodot e gravar_atomico (.tmp, releitura, substituição)

> **Epic**: Save e perfil (persistência)
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/save-e-perfil.md`
**Requirement**: TR-save-002 (parte: gravação só por gravar_atomico), TR-save-010 (parte: Error devolvido, sem laço de nova tentativa)
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

- [ ] **AC-SP-24 [I]** Em raiz temporária: dado um perfil.cfg válido e uma queda simulada em cada passo da sequência atômica (E-P2), o carregamento usa o arquivo antigo ou o novo, nunca um truncado; .tmp sozinho não é promovido.
- [ ] gravar_atomico grava .tmp inteiro, verifica o bool de store_string, relê e compara (para .cfg, reinterpreta) e só então substitui o destino; falha de qualquer passo devolve Error sem laço de nova tentativa.
- [ ] Raiz injetada: testes usam user://_testes/<caso>/ e limpam ao fim; produção usa user://.
- [ ] Resultado do experimento E-P2 (rename sobre destino existente) registrado e a sequência (uma chamada, ou destino→destino.old) escolhida conforme ele.

---

## Implementation Notes

Se EX-0013 (E-P2) mostrar que DirAccess.rename não substitui destino existente no Windows, usar a sequência com .old do ADR-0013 §4. Só ArmazemUserGodot toca FileAccess/DirAccess. A gravação real espera EX-0013; até lá o épico segue com o armazém em memória.

---

## Out of Scope

- Repositórios e formato do perfil: stories 003–005.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/foundation/persistencia/armazem_user_godot.gd
- tests/integration/save/armazem_user_godot_gravacao_atomica_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/armazem_user_godot_gravacao_atomica_test.gd` ou documento de playtest

**Status**: [x] Criado e passando (ver Completion Notes)

---

## Dependencies

- Depends on: [story 001](story-001-armazem-de-arquivos-e-caminhos.md); EX-0013-P1..P7 em production/epics/experimentos-de-engine/EPIC.md (bloqueia a gravação real)
- Unlocks: story 009 (fluxo real)

---

## Completion Notes

**2026-11-16 — engine-programmer (orquestrado, sem commit)**

- **Criados:** `src/foundation/persistencia/armazem_user_godot.gd`, `src/foundation/persistencia/recuperacao_de_gravacao.gd` (plano puro de recuperação de sobras). Testes: `tests/integration/save/armazem_user_godot_gravacao_atomica_test.gd` (11 casos [I], raiz `user://_testes/armazem_user_godot/`, apagada ao fim — conferido que não sobra) e `tests/unit/save/recuperacao_de_gravacao_test.gd` (4 casos). Todos passam.
- **E-P2 (medição rápida, 2026-11-16, Windows 11, Godot 4.7.2 editor headless, projeto descartável no scratchpad):** `DirAccess.rename` sobre destino existente → `OK` e o destino passa a ter o conteúdo novo; com o destino aberto por outro handle → `FAILED` e o destino antigo fica intacto. **Sequência escolhida: uma chamada** (`rename_absolute(tmp, destino)`); a recuperação ainda trata `.old` (inofensiva). Junto: `store_string` devolveu `bool` (confirmado).
- **E-P3 (mesma sessão):** `ConfigFile.parse("%%lixo")`, `""` e só espaços devolvem `OK` **sem seções** (não detecta lixo); `parse` de valor sem fechamento devolve erro e imprime `ERROR: ConfigFile parse error` no log; `int` > 2³¹, `StringName` (tipo 21) e `float` (tipo 3) voltam com o tipo distinguível; `encode_to_text`→`parse`→`encode_to_text` é idêntico; `Dictionary` sai com chaves ordenadas. Consequência usada na story 003: sem seções = corrompido.
- **AC-SP-24:** queda simulada (`simular_queda`: `.tmp` truncado; `.tmp` completo antes da substituição) → a leitura dá o antigo, apaga o `.tmp`; `.tmp` sozinho nunca é promovido; destino ausente + `.old` → restaura. A recuperação roda dentro de `ler_texto` do armazém real.
- **Log:** o único `ERROR:` da suíte é intencional (caso `.cfg` que não reinterpreta).
- **Pendências:** (1) EX-0013-P2 formal no **build exportado** e com destino aberto por **outro processo** (aqui foi o mesmo processo) — `production/epics/experimentos-de-engine/` story-005; (2) E-P1 (`flush`+`get_error`) não medido: `EscritorGodot.descarregar()` segue o ADR provisoriamente.
