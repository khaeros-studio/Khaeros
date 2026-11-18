# Story 004: aplicar_fonte, remover_fonte, avancar: cache e duração

> **Epic**: Modificadores e atributos
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-006, TR-modificadores-007
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md)
**ADR Decision Summary**: Portador (RefCounted) com cache reconstruído em aplicar/remover/avancar; tudo em float até o fim de F1/F2/F3; arredondamento determinístico próprio (sem round()); Modificadores registra e nunca executa.
**ADR Version**: 2026-11-16 (Last Verified; todos Accepted)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: GDScript puro, sem APIs post-cutoff além de @abstract (4.5) e da regra 4.7 de return explícito em override tipado. Experimento EX-0009-1 (production/epics/experimentos-de-engine/EPIC.md) cobre o ponto de risco do ADR.

**Control Manifest Rules (this layer)**:
- Required: Portador extends RefCounted com id_combatente e player_id; agregados reconstruídos em aplicar_fonte/remover_fonte/avancar; fontes em ordem canônica (id_fonte, ordem do efeito) (ADR-0009)
- Forbidden: recalcular agregados em leitura; depender de ordem de Dictionary; round()/roundi()/int() intermediário/epsilon; guardar Vida, escudo, cargas, contador de acertos ou janela pós-esquiva no portador; mutar Modificador/params do catálogo (ADR-0009)
- Guardrail: leitura O(1)/O(k ≤ 3); sem orçamento próprio, entra nos 1,0 ms do passo vivo (ADR-0009, ADR-0001)

---

## Acceptance Criteria

*Do GDD `design/gdd/modificadores-e-atributos.md`, recortados para esta story:*

- [ ] **AC-12 [L] R7** Depois de adicionar, remover ou expirar, a próxima consulta já reflete o novo valor, sem esperar quadro (recálculo imediato).
- [ ] **AC-13 [L]** Remover Preço com Nome retira os 2 modificadores e os gatilhos da fonte.
- [ ] **AC-14 [L]** Remover duas vezes uma fonte inexistente → nada muda, sem erro.
- [ ] **AC-17 [L] R6** Modificador de 2,0 s (= 120 passos): expira exatamente no passo previsto, contado em passos, sem Timer.
- [ ] **AC-18 [L]** Portador de inimigo descartado com modificadores ativos → um (ver GDD) sem vazamento nem ciclo de referência.

---

## Implementation Notes

Duração em contagem de passos (nunca Timer/Time). avancar() decrementa e expira na ordem canônica, reconstruindo o cache. Portador sem referência forte de volta ao combatente.

---

## Out of Scope

- Notificação atributo×recurso: story 007.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/portador.gd (estende)
- tests/unit/modifiers/aplicar_remover_avancar_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/modifiers/aplicar_remover_avancar_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 001](story-001-portador-atributos-e-fontes.md), [story 002](story-002-arredondamento-e-formulas.md)
- Unlocks: stories 005, 007, 008

## Completion Notes

- Código em `src/gameplay/modificadores/` (pasta compartilhada pelas stories 001–004): `portador.gd` (Portador), `consulta_de_atributos.gd` (@abstract), `atributos.gd` (esquema R2), `modificador.gd`, `fonte.gd` (FonteDeModificador), `gatilho_ativo.gd`, `resumo_de_gatilho.gd`, `formulas_de_atributos.gd` (FormulasDeModificadores), `contexto_de_dano.gd`, `dano_congelado.gd`, `ouvinte_de_atributos.gd` (@abstract), `modifiers_tuning.gd` (ModifiersTuning extends DefinicaoBase, tipo tuning). Fábrica de teste: `tests/unit/modifiers/fabrica_de_portadores.gd`. Execução 2026-11-16 de `tests/unit/modifiers`: 47 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
- Teste desta story: `tests/unit/modifiers/aplicar_remover_avancar_test.gd`, 9 casos, todos passando (AC-12, 13, 14, 17, 18 e a duração restante).
- Decisões: reaplicar faz `max(restante, nova)`, e se qualquer lado for permanente a fonte fica permanente (o GDD não cobre esse caso). `duracao_restante` devolve −1 para permanente e 0 para inexistente. O aviso ao `OuvinteDeAtributos` (uma chamada por inteiro alterado, em ordem fixa) já está implementado, porque o AC-18 usa um espião. As reações F4/cargas e o teste de integração ficam na story 007. O `ResumoDeGatilho` básico (total, entradas, params) também já está implementado; a story 005 completa a semântica e os testes dos 8 tipos.
- Pendências: nenhuma. O AC-18 verifica com weakref que o portador e o InimigoRef são liberados e que o espião não recebe chamadas.
