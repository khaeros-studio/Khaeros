# Story 007: Atributo × recurso, cargas, escudo de sala, elite/profundidade e nova run

> **Epic**: Modificadores e atributos
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-009, TR-modificadores-010
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md); [ADR-0001](../../../docs/architecture/adr-0001-orquestrador-do-passo.md)
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

- [ ] **AC-20 [L]** Oráculos F4: 80 → 105; 150 → 145; Vida 100 fica 100; vida_max muda com notificação de valor antigo e novo.
- [ ] **AC-21 [L]** Cargas: máximo 2 → 3 com 2 restantes → 3 restantes; máximo 3 → 2 (conforme GDD).
- [ ] **AC-22 [I] R9** escudo_sala 15 (ver GDD).
- [ ] **AC-23 [L] R10** Elite com base 30 → Vida 72, dano_todo × 1,25, raio (ver GDD): elite e profundidade aplicadas como fontes no spawn.
- [ ] **AC-16 [I]** 3 bênçãos e Vigor nv2, fim da run, nova run → vida_max do começo (portador descartado e recriado).
- [ ] **AC-19 [L]** Oráculos F5: Preço com Nome Rara → +0,30 de dano e −10 de Vida.

---

## Implementation Notes

Notificação por chamada síncrona (valor antigo, valor novo) ao dono do recurso — nunca sinal do Godot. Combate e Movimento reagem; Modificadores não escreve recursos.

---

## Out of Scope

- Reação do Combate ao clamp de Vida: épico combate-nucleo. Cargas de esquiva: movimento-e-esquiva story 004.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/portador.gd (estende), notificador_de_atributo.gd
- tests/unit/modifiers/atributo_x_recurso_test.gd
- tests/integration/modifiers/escudo_sala_e_nova_run_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/modifiers/atributo_x_recurso_cargas_elite_run_test.gd` ou documento de playtest

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [story 002](story-002-arredondamento-e-formulas.md), [story 004](story-004-aplicar-remover-avancar.md); production/epics/ia-de-inimigos-e-elites/EPIC.md (spawn de elite)
- Unlocks: production/epics/movimento-e-esquiva/story-004-cargas-e-recarga.md

## Completion Notes

- Arquivos: `src/gameplay/modificadores/notificador_de_atributo.gd` (NotificadorDeAtributo extends OuvinteDeAtributos: despachante por atributo + reações puras da R9/F4: `vida_apos_mudar_max`, `restantes_apos_mudar_max`, `escudo_apos_mudar`, `escudo_no_comeco_da_camara`, `vida_no_comeco_da_run`); fontes de spawn `fonte_elite`, `fonte_chefe`, `fonte_profundidade` em `aplicador_de_efeitos.gd`. Testes: `tests/unit/modifiers/atributo_x_recurso_test.gd` (6 casos) e `tests/integration/modifiers/escudo_sala_e_nova_run_test.gd` (2 casos: AC-22, AC-16), passando.
- Decisões: `EliteRules.resistencia_empurrao` é lido como o multiplicador de `fator_empurrao` (0,4); o percentual de profundidade chega já calculado pela IA (dona do `depth_hp_bonus`). Arquivo de integração com nome diferente do sugerido no Test Evidence.
- Pendências: o Main precisa compor o NotificadorDeAtributo e registrar Combate/Bênçãos como ouvintes; a IA precisa aplicar as fontes no spawn (épicos combate-nucleo, ia-de-inimigos-e-elites).
- Execução 2026-11-16 de tests/unit/modifiers + tests/integration/modifiers: 82 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
