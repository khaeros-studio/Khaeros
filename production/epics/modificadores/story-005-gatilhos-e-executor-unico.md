# Story 005: Gatilhos: ResumoDeGatilho cacheado e semântica do executor único

> **Epic**: Modificadores e atributos
> **Status**: Done
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/modificadores-e-atributos.md`
**Requirement**: TR-modificadores-011
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

- [ ] **AC-25 [L] R11** Para os 8 tipos de gatilho, gatilhos(tipo) devolve a lista por tipo (ResumoDeGatilho cacheado), em ordem canônica.
- [ ] **AC-26 [L]** Os Que Ficam + Recusa dos Que Ficam → total 2; params não escalam.
- [ ] **AC-29..31 [L] R12/R13/Abalo** conforme o GDD (seção Acceptance Criteria): semântica do executor único e Abalo com um único relógio, no Status.
- [ ] Modificadores só registra; nenhuma execução de gatilho acontece dentro do portador.

---

## Implementation Notes

Executores (Combate, Status, Selo) leem gatilhos(); AplicadorDeEfeitos aplica F5 ao valor, nunca aos params. Abalo tem um único relógio, no Status (épico efeitos-de-status).

---

## Out of Scope

- Executores concretos: épicos combate-nucleo, efeitos-de-status, bencaos-tradicoes.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/modificadores/resumo_de_gatilho.gd, portador.gd (estende)
- tests/unit/modifiers/gatilhos_e_executor_unico_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/modifiers/gatilhos_e_executor_unico_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 004](story-004-aplicar-remover-avancar.md)
- Unlocks: production/epics/combate-nucleo/EPIC.md; production/epics/bencaos-tradicoes/EPIC.md

## Completion Notes

- Arquivos: `tests/unit/modifiers/gatilhos_e_executor_unico_test.gd` (9 casos, passando). Código: o `ResumoDeGatilho`/`Portador.gatilhos` das stories 001–004 já cumpria a R11; usa `TabelaDeEfeitos.tipos_de_gatilho()` e `AplicadorDeEfeitos` (story 006).
- Cobertos: AC-25 (8 tipos, entradas por fonte em ordem canônica, total, params; tipo de atributo fora de gatilhos; `recusas_morte` nos dois), AC-26 (total 2, params não escalam), AC-29 (M congelado no disparo, 4º acerto no impacto, investida 2,1), AC-31 (Abalo lido no disparo → 7; fonte única ×0,7 e `max` de duração). Resumo somente leitura; o portador não executa nada.
- Fora daqui (executores): partes do AC-29/30 de Combate (reflexo, cadeia de explosões, recusa, contador de acertos) e o relógio do Abalo (Status) — épicos combate-nucleo e efeitos-de-status.
- Execução 2026-11-16 de tests/unit/modifiers + tests/integration/modifiers: 82 casos, 0 erros, 0 falhas, 0 órfãos, sem erro de parse.
