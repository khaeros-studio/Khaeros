# Story 006: Tabela fechada das 21 chaves, validação, paridade com o cânone e tuning

> **Epic**: Modificadores e atributos
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-005, TR-modificadores-012, TR-modificadores-013
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md); [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md)
**ADR Decision Summary**: Portador (RefCounted) com cache reconstruído em aplicar/remover/avancar; tudo em float até o fim de F1/F2/F3; arredondamento determinístico próprio (sem round()); Modificadores registra e nunca executa. O validador do catálogo (V1–V11) recebe a tabela fechada das 21 chaves.
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

- [ ] **AC-27 [L]** A lista de tipos tem exatamente 21, em bijeção com a lista fixa do GDD.
- [ ] **AC-28 [L]** Modificador com atributo fora da R2 ou condição desconhecida → rejeitado pelo validador.
- [ ] **AC-06 [L]** Muro de Pedras, Preço com Nome, Vigor nv2 e Ímpeto nv3 nas 24 combinações do GDD.
- [ ] **AC-32 [I]** Teste de tabela de paridade com o cânone (manter no teste de integração).
- [ ] Valores de tuning vêm do catálogo validado; valor já escalado, params não escalam (TR-modificadores-013).

---

## Implementation Notes

A tabela é entregue ao validador de conteúdo (ADR-0004). O teste de paridade vive em tests/integration/modifiers/ e usa o catálogo real quando o épico conteudo estiver pronto; até lá, fixture em memória. Valores nunca no código.

---

## Out of Scope

- Importação CSV→.tres: épico conteudo.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/tabela_de_efeitos.gd
- tests/unit/modifiers/tabela_das_21_chaves_test.gd
- tests/integration/modifiers/paridade_de_tabela_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check em `production/qa/smoke-*.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [story 001](story-001-portador-atributos-e-fontes.md); production/epics/conteudo/EPIC.md (validador e catálogo)
- Unlocks: story 008

## Completion Notes

- Arquivos: `src/gameplay/modificadores/tabela_de_efeitos.gd` (TabelaDeEfeitos: 21 linhas tipo→cânone/espécie/atributo/operação/condição+nome do param/slots/executor; `registrar_em(RegistrosDeChaves)` entrega `tipos_de_efeito` e `atributos_portador_maldicao`), `src/gameplay/modificadores/aplicador_de_efeitos.gd` (AplicadorDeEfeitos: F5 só no valor; condicional multiplicador vira 1+valor; tipo desconhecido ou param de condição ausente → relator e ignorado), `tests/fixtures/modifiers/player_mods_canon.txt`, `tests/unit/modifiers/tabela_das_21_chaves_test.gd` (8 casos, passando: AC-27, AC-28 via V4Referencias, AC-06 nas 24 ordens, AC-19/F5).
- Decisões: o teste do AC-27 lê o fixture .txt com FileAccess (o GDD pede esse arquivo); `Atributos.DA_MALDICAO` criado em atributos.gd.
- Pendências: (1) AC-32: `tests/integration/modifiers/paridade_de_tabela_test.gd` não foi criado — precisa do oráculo `tests/fixtures/modifiers/paridade_canon.gd` gerado por `tools/canon-parity/` (tools-programmer). (2) O Main/carregador do catálogo precisa chamar `TabelaDeEfeitos.registrar_em(registros)` antes da validação (não editei main.gd nem o épico conteudo). (3) Smoke check em production/qa/smoke-*.md não feito (gate advisory).
- Execução 2026-11-16 de tests/unit/modifiers + tests/integration/modifiers: 82 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
