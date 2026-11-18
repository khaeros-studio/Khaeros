# Story 002: Ordem canônica, arredondamento determinístico e F1/F2/F3

> **Epic**: Modificadores e atributos
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-008
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md); [ADR-0010](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) (um arredondamento só)
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

- [ ] **AC-04b [L]** F2 — teto do M (teto_multiplicador_dano = 4,0): M calculado 14,08 (tudo Épico, 4º acerto, pós-esquiva) → M efetivo 4,0; teto aplicado por último.
- [ ] **AC-05 [L]** arredondar_meio_longe_do_zero: 22,5 → 23 e 22,4 → 22; os 5 atributos inteiros devolvem int.
- [ ] **AC-10 [L]** Oráculos F2 (valores no GDD).
- [ ] **AC-24 [L]** Oráculos F3 (valores no GDD).
- [ ] Soma de fontes em ordem canônica; resultado idêntico independentemente da ordem de inserção.

---

## Implementation Notes

Função própria arredondar_meio_longe_do_zero (nunca round()/roundi()). Arredondar só nos 5 atributos inteiros e em F3. Tolerância de teste 1e-6 (cabeçalho dos AC). Testes de determinismo: embaralhar a ordem de aplicação e comparar bit a bit.

---

## Out of Scope

- Condicionais por contexto: story 003.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/formulas_de_atributos.gd, arredondamento.gd
- tests/unit/modifiers/arredondamento_e_formulas_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/modifiers/arredondamento_e_formulas_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 001](story-001-portador-atributos-e-fontes.md)
- Unlocks: stories 003, 007, 008

## Completion Notes

- Código em `src/gameplay/modificadores/` (pasta compartilhada pelas stories 001–004): `portador.gd` (Portador), `consulta_de_atributos.gd` (@abstract), `atributos.gd` (esquema R2), `modificador.gd`, `fonte.gd` (FonteDeModificador), `gatilho_ativo.gd`, `resumo_de_gatilho.gd`, `formulas_de_atributos.gd` (FormulasDeModificadores), `contexto_de_dano.gd`, `dano_congelado.gd`, `ouvinte_de_atributos.gd` (@abstract), `modifiers_tuning.gd` (ModifiersTuning extends DefinicaoBase, tipo tuning). Fábrica de teste: `tests/unit/modifiers/fabrica_de_portadores.gd`. Execução 2026-11-16 de `tests/unit/modifiers`: 47 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
- Teste desta story: `tests/unit/modifiers/arredondamento_e_formulas_test.gd`, 13 casos, todos passando (AC-04b, 05, 10, 24 e as 24 permutações comparadas bit a bit).
- Decisões: F1, F2 e F3 e o arredondamento estão em uma única classe `FormulasDeModificadores` (`formulas_de_atributos.gd`, nome do ADR). Não criei o `arredondamento.gd` separado. A F3 também expõe `vida_perdida`/`escudo_restante`. O oráculo de 14,08 usa uma fixture com 1 + P = 3,2 × 2,2 × 2,0, porque a combinação "tudo Épico" do GDD não fecha em 14,08 com os valores Comum ×2. Recomendo que o designer revise esse exemplo.
