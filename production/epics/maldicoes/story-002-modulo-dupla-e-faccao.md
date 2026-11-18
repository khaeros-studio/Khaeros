# Story 002: ModuloDeMaldicoes, MaldicaoRef e a dupla da expedição (facção ALIADO)

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R1, R2, R23)
**Requirement**: `TR-maldicoes-001`, `TR-maldicoes-002`, `TR-maldicoes-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0003: Entidades e portadores; ADR-0010: Resolução do combate no passo; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `ModuloDeMaldicoes extends RefCounted` com colaboradores injetados e estado em `Array[EstadoDoPacto]` por `player_id`. `MaldicaoRef` tem id do espaço do ADR-0003, `player_id`, facção `ALIADO`, `Portador` próprio nunca destruído na Exaustão; fica fora das listas de inimigos, de atingíveis e da contagem de câmara limpa. `passo_maldicoes()` roda só em passo vivo, sub-passos 1–8 da R23.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0017: só `RefCounted`, `Vector2`, `Array` tipado, `StringName`. Dublês com retorno tipado: `return` explícito.

**Control Manifest Rules (Core — o manifesto põe Maldições na camada Core)**:
- Required: ordem da R23 no item 6.1; jogadores e alvos por id crescente; tudo por `player_id`; sem fogo amigo por construção
- Forbidden: `Node`, `Area2D`, `Timer`, sinal do Godot, RNG, campo singular "a Maldição"
- Guardrail: item 6.1 ≤ 0,1 ms (medido na story 009)

---

## Acceptance Criteria

- [x] AC-ML-01 (R1): Virote, Selo, explosão ou status sobre a área ferem o inimigo em `(640, 540)` e deixam Vida e estados da Maldição em `(600, 540)` inalterados.
- [x] AC-ML-02 (R1): com o último inimigo morto e uma Maldição em campo com `Vida = 110`, `camara_limpa` é emitida normalmente.
- [x] AC-ML-03 (R2): dupla `["vulto_mudo", "espreitador_da_fenda"]` → `vulto_mudo` nasce em campo a 105 px do jogador com `Vida = 110`; `espreitador_da_fenda` na reserva `Pronta` com `Vida = 95`.
- [x] Esqueleto do 6.1: os 8 sub-passos são chamados na ordem da R23 e nada roda em passo congelado (teste com dublês; o conteúdo dos sub-passos vem nas stories 003–008).

---

## Implementation Notes

- Construtor recebe `MaldicoesTuning` convertido, `CurseDef`s, consulta do Combate, fachada da IA, consulta do Status, posições dos jogadores, geometria da câmara e `EventosDoPasso`; sem tuning válido, falha na criação.
- O módulo é criado pela `FabricaDaRun` (ADR-0015) e descartado no fim da run; não usar `reset()`.
- Implementar `maldicao_em_campo(player_id)`, `maldicao_atingivel(id)` (em campo, Vida > 0, não `SALTANDO`), `posicao_e_raio`, `portador_de`, `descontar_vida` (só o Combate chama).
- `MaldicaoRef`: campos do §2 do ADR-0017.

---

## Out of Scope

- 003 IA de aliado; 004 ataque básico; 005 dano e Exaustão; 006 contadores; 007 troca; 008 Chamado; 009 câmara/leitura/eventos.

---

## Files

- `src/gameplay/maldicoes/modulo_de_maldicoes.gd`, `maldicao_ref.gd`, `estado_do_pacto.gd`
- `tests/unit/maldicoes/modulo_dupla_e_faccao_test.gd`

Código da fatia: nada reaproveitado. `src/gameplay/game_session.gd` não ganha Maldições (a composição é do épico `run-e-regioes`).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/maldicoes/modulo_dupla_e_faccao_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-001-catalogo-e-validacao-ml.md`; épicos `production/epics/orquestrador-do-passo/`, `production/epics/modificadores/` (Portador), `production/epics/combate-nucleo/` (facção, lista de atingíveis)
- Unlocks: stories 003–009 deste épico
