# Story 001: Portador: atributos, piso/teto, estrutura do modificador e F1

> **Epic**: Modificadores e atributos
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-001, TR-modificadores-002, TR-modificadores-003
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md); [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md)
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

- [ ] **AC-01 [L]** Portador sem modificadores, base vida_max 130 → valor 130 (atributos derivados separados dos recursos).
- [ ] **AC-02 [L]** Adicionar e remover velocidade_pct não muda a Vida atual (80).
- [ ] **AC-03 [L]** Oráculos F1: 175; 165; base 25 − 10 → 20; Muro de Pedras Raro (valores exatos no GDD).
- [ ] **AC-04 [L]** Pisos e tetos da lista fechada de atributos.
- [ ] **AC-15 [L]** Muro de Pedras aplicado 2× → 155, não 180; Vigor nível 3 = uma fonte (estado do portador independente por instância; definição do catálogo intacta).

---

## Implementation Notes

**Código atual da fatia**: nenhum sistema de modificadores; as bênçãos de src/gameplay/game_session.gd são aplicadas de forma explícita — construir do zero e converter cada bênção da fatia em caso de teste (oráculo), sem importar o código. Estrutura: Portador, Modificador (imutável após criar), Fonte (id_fonte, origem, lista de modificadores e gatilhos). Instância por combatente (duplicate_deep quando houver sub-recursos). Lista fechada de atributos com piso/teto vem do tuning do catálogo.

---

## Out of Scope

- story 002: arredondamento e F2/F3. story 004: aplicar/remover/avancar completos. story 006: tabela das 21 chaves.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/portador.gd, modificador.gd, fonte.gd, atributos.gd
- tests/unit/modifiers/portador_atributos_e_fontes_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/modifiers/portador_atributos_e_fontes_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: production/epics/orquestrador-do-passo/EPIC.md (Main/injeção), production/epics/conteudo/EPIC.md (catálogo e validador)
- Unlocks: stories 002–008

## Completion Notes

- Código em `src/gameplay/modificadores/` (pasta compartilhada pelas stories 001–004): `portador.gd` (Portador), `consulta_de_atributos.gd` (@abstract), `atributos.gd` (esquema R2), `modificador.gd`, `fonte.gd` (FonteDeModificador), `gatilho_ativo.gd`, `resumo_de_gatilho.gd`, `formulas_de_atributos.gd` (FormulasDeModificadores), `contexto_de_dano.gd`, `dano_congelado.gd`, `ouvinte_de_atributos.gd` (@abstract), `modifiers_tuning.gd` (ModifiersTuning extends DefinicaoBase, tipo tuning). Fábrica de teste: `tests/unit/modifiers/fabrica_de_portadores.gd`. Execução 2026-11-16 de `tests/unit/modifiers`: 47 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
- Teste desta story: `tests/unit/modifiers/portador_atributos_e_fontes_test.gd`, 17 casos, todos passando (AC-01, 02, 03, 04, 15 e o AC-28 em execução).
- Decisões: `ModifiersTuning` foi criado aqui, porque o épico conteudo o deixou para o épico dono (conteudo story-002). Os limites fixos da R2 (≥ 0, cargas ≥ 1, fator_empurrao 0–1) ficam como esquema em `Atributos`; os ajustáveis vêm do tuning. Modificador inválido (atributo fora da R2, condição fora de `dano_todo`, multiplicador negativo) é ignorado e vai para o `RelatorDeErros`, reaproveitando `RelatorDeErros.Entrada` com tipo `&"modificador"`. O cânone diz `raio` > 0, mas está implementado como piso 0.
- Pendências: o carregador/manifesto do catálogo ainda não conhece `ModifiersTuning` (épico conteudo). Falta `fontes_de()`/`LinhaDeFonte` para o HUD (ADR-0009 Key Interfaces), que fica para a story do HUD/Tela.
