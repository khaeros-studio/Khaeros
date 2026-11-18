# Story 006: Montagem na Transição — teleporte, Maldição, acuada e 1ª onda

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R4, R4-P, R19-P, F6)
**Requirement**: `TR-camaras-002`, `TR-camaras-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo; ADR-0015: Ciclo da run e composição (§4.1); ADR-0017: Aliados e invocações; ADR-0008: Movimento e colisão própria
**ADR Decision Summary**: `Camaras.trocar(i, recompensa_pendente)` roda no quadro da metade do wipe (seis ações da Transição), depois do teleporte: descarta o `ConteudoDaCamara`, monta layout e ondas, pede `reposicionar_maldicao(pos)` e `vinculo.ao_montar_camara(i, montador)` (acuada em pontos fixos, sem RNG, `pos_acuada` guardada) e faz nascer a 1ª onda no mesmo quadro.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0001)
**Engine Notes**: Risco do épico: montar layout + ondas + 1ª onda num quadro da Transição — medir o custo do quadro (perfil headless) e registrar no relatório da story.

**Control Manifest Rules (Feature)**:
- Required: `cancelar_todos()` dos Telégrafos antes de as Câmaras removerem inimigos
- Forbidden: `SceneTree.paused`; criar `Node` por inimigo na lógica

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-02: na metade do wipe, depois do teleporte, o jogador fica em (960; 930), a fase é Combate e a 1ª onda nasce no mesmo quadro.
- [x] AC-CO-35: Maldição em campo (raio 30) → `reposicionar_maldicao((960; 1035))`; com `distancia_seguir_px` 150 → (960; 1050); sem Maldição, nenhum pedido.
- [x] AC-CO-36: `encontro_na_camara(1)` consultado depois do layout e da composição e antes da 1ª onda; Vínculo recebe a lista de pedras; consumo dos fluxos igual ao sem encontro.
- [x] AC-CO-41: mesma seed com e sem encontro no índice 2 → layout, ondas e elites idênticos.

---

## Implementation Notes

- Ordem do ADR-0015 §4.1: layout → `ao_montar_camara` (acuada) → 1ª onda.
- A Fixture CO-P usa dublês de Vínculo, Maldições e Chefes.

---

## Out of Scope

- Épico cena-e-camera: wipe e teleporte visuais
- Épico vinculo-e-pactos: planejamento do encontro

---

## Files

- `src/gameplay/camaras/camaras.gd`
- `src/gameplay/camaras/conteudo_da_camara.gd`
- `tests/integration/camaras/montagem_na_transicao_test.gd`

Código atual da fatia: `game_session.gd::advance_presentation` (transição por `transition_progress` e `_spawn_wave`) é **substituído** pela Transição do orquestrador + `Camaras.trocar`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/camaras/montagem_na_transicao_test.gd`
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-002-profundidade-e-sequencia.md`, `production/epics/camaras-e-ondas/story-005-spawn-e-candidatos.md`; `production/epics/orquestrador-do-passo/EPIC.md` (Transição), `production/epics/maldicoes/EPIC.md`, `production/epics/vinculo-e-pactos/EPIC.md` (stories a criar; dublês até lá)
- Unlocks: `production/epics/camaras-e-ondas/story-007-ciclo-de-combate-e-limpar.md`
