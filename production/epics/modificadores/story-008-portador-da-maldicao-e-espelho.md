# Story 008: Portador da Maldição: origens vinculo/especie/espelho e propagação

> **Epic**: Modificadores e atributos
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-014, TR-modificadores-015, TR-modificadores-016
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md); [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md); [ADR-0003](../../../docs/architecture/adr-0003-entidades-e-portadores.md)
**ADR Decision Summary**: Portador (RefCounted) com cache reconstruído em aplicar/remover/avancar; tudo em float até o fim de F1/F2/F3; arredondamento determinístico próprio (sem round()); Modificadores registra e nunca executa. Um portador por Maldição da dupla, persistente na Exaustão e na reserva, criável no passo de um pacto; espelho por tipos_propagados_maldicao e fator_propagacao_maldicao.
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

- [ ] **AC-33 [L] R14** CurseDef do Baluarte (vida_max 135, ...): portador da Maldição conforme GDD; lista restrita de atributos.
- [ ] **AC-34 [L] R14/F6** Jogador com Preço com Nome Comum (+0,20 ...): espelho conforme GDD.
- [ ] **AC-35 [L] R14** Jogador com Traço Único, Fundo do Poço (...): espelho só dos tipos propagados.
- [ ] **AC-36 [L] F6** Fio Invisível Épico no jogador (consulta da Maldição).
- [ ] **AC-37 [L] F6/F2** Espelhos que somariam P_todo_m 4,5 → respeita o teto 4,0.
- [ ] **AC-38 [L] R14** Fonte vinculo:vulto_mudo de +10 vida_max (origens vinculo, especie, espelho).
- [ ] **AC-39 [L] R14/R6** Portador de Maldição com espelho de 120 passos (expiração).
- [ ] **AC-40 [L] R14** Criação no meio da run (emenda Pactos): portador criável no passo de um pacto; furia como fonte.
*(Valores completos no GDD, AC-33..40.)*

---

## Implementation Notes

Espelho entra e sai com a fonte do jogador em todos os portadores da dupla. Portador nunca destruído na Exaustão ou na reserva. Tudo por player_id (0 no solo). Sem fogo amigo e sem RNG na Maldição (ADR-0017).

---

## Out of Scope

- Módulo de Maldições (item 6.1): épico maldicoes.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/portador_da_maldicao.gd, espelho_de_fontes.gd
- tests/unit/modifiers/portador_da_maldicao_e_espelho_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/modifiers/portador_da_maldicao_e_espelho_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 002](story-002-arredondamento-e-formulas.md), [story 004](story-004-aplicar-remover-avancar.md), [story 006](story-006-tabela-das-21-chaves-e-tuning.md); production/epics/maldicoes/EPIC.md (consome)
- Unlocks: production/epics/maldicoes/EPIC.md

## Completion Notes

- Arquivos: `src/gameplay/modificadores/portador_da_maldicao.gd` (PortadorDaMaldicao.criar / criar_no_pacto / vida_ao_nascer_no_pacto), `src/gameplay/modificadores/espelho_de_fontes.gd` (EspelhoDeFontes: espelho `espelho:<fonte>` por tipo via `TabelaDeEfeitos.tipo_do_modificador`, valor × fator, duração restante; aplicar/remover/sincronizar/adicionar_maldicao). `portador.gd`: `fonte_ativa(id)` e recusa (relator) de atributo fora de `Atributos.DA_MALDICAO` em portador MALDICAO. Teste: `tests/unit/modifiers/portador_da_maldicao_e_espelho_test.gd` (10 casos, passando: AC-33..40).
- Decisões: depois do `avancar` do jogador o dono chama `EspelhoDeFontes.sincronizar()` (expiração não é automática entre portadores); fator 0 não cria espelho; o tamanho máximo da dupla é injetado pelo dono (Maldições).
- Pendências: integração com o módulo de Maldições (épico maldicoes) — criação no começo da run e no pacto, e a Vida da Maldição.
- Execução 2026-11-16 de tests/unit/modifiers + tests/integration/modifiers: 82 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
