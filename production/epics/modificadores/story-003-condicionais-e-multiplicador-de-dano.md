# Story 003: Condicionais avaliados no uso e multiplicador_de_dano(contexto)

> **Epic**: Modificadores e atributos
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-004
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

- [ ] **AC-07 [L]** vida_abaixo (máx 100, Fundo do Poço Comum): Vida 49,9 → M 1,4 (valores completos no GDD).
- [ ] **AC-08 [L]** enesimo_acerto (Linha Contada Comum): contador 3 → 1,0 (demais pontos no GDD).
- [ ] **AC-09 [L]** apos_esquiva (Penumbra Comum): ativo só com contexto.apos_esquiva.
- [ ] **AC-11 [L]** Corte Fantasma Comum (valor 10) com Traço Único Comum (+25% Ataque): composição conforme GDD.
- [ ] Contexto passado por quem consulta; o portador não guarda Vida, contador de acertos nem janela pós-esquiva.

---

## Implementation Notes

multiplicador_de_dano(contexto: ContextoDeDano) avalia condições no uso. Condição desconhecida é rejeitada no validador (story 006), aqui só falha em diagnóstico.

---

## Out of Scope

- Executor de gatilhos: story 005.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/contexto_de_dano.gd, portador.gd (estende)
- tests/unit/modifiers/condicionais_e_multiplicador_de_dano_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/modifiers/condicionais_e_multiplicador_de_dano_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 002](story-002-arredondamento-e-formulas.md)
- Unlocks: production/epics/movimento-e-esquiva/story-007-corte-da-esquiva.md; production/epics/combate-nucleo/EPIC.md

## Completion Notes

- Código em `src/gameplay/modificadores/` (pasta compartilhada pelas stories 001–004): `portador.gd` (Portador), `consulta_de_atributos.gd` (@abstract), `atributos.gd` (esquema R2), `modificador.gd`, `fonte.gd` (FonteDeModificador), `gatilho_ativo.gd`, `resumo_de_gatilho.gd`, `formulas_de_atributos.gd` (FormulasDeModificadores), `contexto_de_dano.gd`, `dano_congelado.gd`, `ouvinte_de_atributos.gd` (@abstract), `modifiers_tuning.gd` (ModifiersTuning extends DefinicaoBase, tipo tuning). Fábrica de teste: `tests/unit/modifiers/fabrica_de_portadores.gd`. Execução 2026-11-16 de `tests/unit/modifiers`: 47 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
- Teste desta story: `tests/unit/modifiers/condicionais_e_multiplicador_de_dano_test.gd`, 8 casos, todos passando (AC-07, 08, 09, 11 e o M congelado no disparo).
- Decisões: `congelar_dano(slot, ctx)` devolve `DanoCongelado`, e `m_no_impacto(contador)` aplica o 4º acerto e depois o teto. `multiplicador_de_dano` equivale a `m_no_impacto(0)`. A máscara `slots` vale para qualquer modificador de `dano_todo` (Slot.NENHUM = inimigo, só incondicionais sem máscara). O contador de acertos, a Vida e a janela ficam fora do portador.
