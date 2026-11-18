# Story 004: AudioDoJogo — pools no _ready, barramentos, volumes e comportamento por estado

> **Epic**: Áudio: ganchos e vozes
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O nó da Apresentação, 5º consumidor da entrega: cria os 25 `AudioStreamPlayer` (Efeitos 16, Tons 3, Interface 4, Música 2) no `_ready`, resolve os 4 barramentos e os `SomDef` na construção da run, aplica os comandos do Mixador e do Seletor e segue a tabela de estados (pausa, Bênção, Transição, Morte, Nova run).

**GDD**: `docs/architecture/adr-0016-audio-ganchos-e-vozes.md` (requisitos de `design/gdd/feedback-de-combate.md` Edge Cases e `design/gdd/telegrafos.md`)
**Requirement**: `TR-feedback-008`, `TR-telegrafos-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes; ADR-0001: Orquestrador do passo; ADR-0013: Persistência do MVP
**ADR Decision Summary**: Ordem de entrega Telemetria → HUD → Feedback → Telas → Áudio; estado por consulta `estado_de_jogo()`; volumes lineares de `opcoes.cfg [audio]` (0 = mudo, senão `linear_to_db`); barramento ausente → aviso e `Master`; liberação por consulta de `playing`, sem sinal `finished`.
**ADR Version**: ADR-0016 2026-11-16; ADR-0001 2026-11-16; ADR-0013 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Antes de começar, o EX-0016-A precisa confirmar: `pitch_scale` em tempo real, `stream_paused` retomando da mesma posição, `get_bus_index` = −1 para nome inexistente, `volume_db`, `linear_to_db()`, layout de barramentos e laço do stream importado (todos NOT SOURCEABLE ou NEEDS VERIFICATION). Fallbacks do ADR: pausa por `stop()` + `get_playback_position()`; tom por 3 streams pré-transpostos. Evita `AudioStreamPlayer2D/3D` e `AudioStreamPolyphonic`.

**Control Manifest Rules (this layer)**:
- Required: `AudioDoJogo` cria todos os players no `_ready`; P0 nunca é roubada; ≤ 3 tons; entrega sem alocar
- Forbidden: never instanciar players fora do `_ready`; never `Engine.time_scale`/`SceneTree.paused` para pausar; never o Áudio emitir evento ou escrever em módulo de regra
- Guardrail: áudio < 0,05 ms por passo

---

## Acceptance Criteria

*From ADR-0016 Validation V-4, V-5 and `design/gdd/feedback-de-combate.md` Edge Cases:*

- [x] V-4: entrega na ordem Telemetria → HUD → Feedback → Telas → Áudio; pedido de Tela e de Feedback no mesmo passo resolvidos juntos
- [x] V-4: `PAUSA` pausa e retoma os Efeitos de onde pararam e mantém a Interface tocando (AC-FB-26, lado áudio)
- [x] V-4: gancho sem `SomDef` → um aviso `FB2` por run
- [x] Transição: vozes já tocando terminam e os tons param no passo em que a publicação esvazia (AC-FB-24, "ganchos já emitidos tocam"); Nova run: `parar_tudo()` e Mixador zerado
- [x] V-5: 600 passos de multidão sem crescimento de objetos (monitor de objetos antes e depois)
- [x] Volumes: 0 → `set_bus_mute`; valor fora de [0, 1] ou de outro tipo volta ao padrão (1,0 master, 0,8 demais)

---

## Implementation Notes

*Derived from ADR-0016 §1–§7 and Implementation Guidelines:*

- `consumir_passo(pedidos_feedback, estado, vistas, quantas_vistas)`, `aplicar_volumes(...)`, `parar_tudo()`; nomes de barramento como `StringName` em `BarramentosDeAudio`.
- Recarga do catálogo: com ajustes vazios, para tudo e fica mudo.
- Testes de integração headless com driver de áudio dummy.
- Medir o custo por passo com a cena de multidão do Pipeline, antes e depois (registrado na story 005).

---

## Out of Scope

- Tela de opções e gravação de `opcoes.cfg [audio]` (épicos hud/persistencia)
- Story 005: escuta em playtest

---

## Files

- `src/presentation/audio/audio_do_jogo.gd`, `barramentos_de_audio.gd`
- `default_bus_layout.tres` (caminho padrão a confirmar no EX-0016-A)
- `src/app/main.gd` (compor e registrar como 5º consumidor)
- `tests/integration/audio/audio_do_jogo_no_test.gd`

Código da fatia: `src/app/main.gd` — **adaptar** para compor `AudioDoJogo` e a `FilaDeSonsDeInterface` injetada em Telas/HUD; a fatia não toca som.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/audio/audio_do_jogo_no_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/audio/audio_do_jogo_test.gd`, `production/qa/evidence/audio-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/audio/story-002-mixador-de-vozes.md`, `production/epics/audio/story-003-seletor-de-tons-dos-telegrafos.md`, `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`; `production/epics/experimentos-de-engine/EPIC.md` (EX-0016-A); `production/epics/orquestrador-do-passo/EPIC.md` (entrega e `estado_de_jogo()`); `production/epics/persistencia/EPIC.md` (`opcoes.cfg [audio]`)
- Unlocks: `production/epics/audio/story-005-escuta-e-medicao-em-playtest.md`
