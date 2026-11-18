# Story 001: Modelo do HUD — leitura injetada, relógio de interface e HudTuning

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R1, R14, Tuning Knobs, Game Feel)
**Requirement**: `TR-hud-001`, `TR-hud-002`, `TR-hud-007`, `TR-hud-008`, `TR-hud-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0002: Canal de eventos; ADR-0004: Catálogo de dados
**ADR Decision Summary**: O `ModeloDoHud` (RefCounted) recebe por injeção `LeituraDoHud` (`@abstract`, só consultas), `HudTuning`, `RelogioDeInterface` e `player_id`; a cada entrega do passo lê os eventos só para animar e **sempre** reconsulta os valores; na criação lê tudo por consulta. `RelogioDeInterface` tem `t_ui()` (para na pausa) e `t_real()`.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0002 2026-11-16 · ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `@abstract` (4.5) com retorno tipado não-void exige `return` explícito nas implementações (4.7). Sem `Timer`/`create_timer`/`Tween` sem controle de pausa.

**Control Manifest Rules (Presentation)**:
- Required: HUD lê valores por consulta em toda entrega e na criação; animações de UI por `t_ui`/`t_real` (`RelogioDeInterface` avançado pelo `Main._process` com `min(delta_real, dt_max)`)
- Forbidden: o HUD guardar estado de jogo ou chamar método de escrita; `Timer`, `create_timer` ou `Tween` sem controle de pausa
- Guardrail: sem alocação no caminho quente (dicionários reaproveitados pelo adaptador real; ADR-0012 Performance)

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md`, scoped to this story:*

- [x] AC-HD-21 [L] R1 — a interface de leitura passada ao HUD não expõe nenhum método de escrita; o HUD roda com fontes falsas, sem cena de jogo (R14).
- [x] AC-HD-31 [L] R14 — recriar o HUD na Transição com O Fundo do Poço, saldo 26, Vida 40/100 e Fluxo 40: marca de 50%, saldo, Vida e Fluxo aparecem sem receber evento.
- [x] AC-HD-24 [L] Edge — "+5" com 1,0 s restante: pausar 10 s e retomar mantém 1,0 s restante (relógio `t_ui` para com a pausa).
- [x] AC-HD-37 [L] Validação — `HudTuning` com `margem_segura_px` 70 gera HU14; `vinheta_opacidade_max` 0,50 gera HU7; `vida_por_segmento` 4 gera HU1; o dado de fábrica não gera HU; cada um dos 14 campos fora da faixa gera só o seu código (e HU15–HU17 dos campos do Pacto).
- [x] Game Feel — latência: todo valor exibido muda em ≤ 1 passo do evento da fonte (teste com fonte falsa que muda e entrega no mesmo passo).

---

## Implementation Notes

*Derived from ADR-0012 §2, §6 e Key Interfaces; ADR-0004 (validação por tipo):*

- `LeituraDoHud` exatamente como em ADR-0012 Key Interfaces (`vida`, `escudo`, `recusas`, `fluxo`, `esquiva`, `saldo`, `limiar_fundo_do_poco`, `inimigos_feridos`, `porta_interagivel`, `estado_de_jogo`, `hitstop_ativo`, `chefe`, `estado_pacto`). Nenhum método de escrita.
- `ModeloDoHud.entregar(eventos)`: (a) eventos só disparam animações; (b) reconsulta todos os valores. Um evento perdido atrasa a animação, nunca o valor.
- `RelogioDeInterface.avancar(delta_real, pausado)`; `t_ui()` para em `PAUSA`, `t_real()` nunca para. `t_apres` não serve (fica parado em `BENCAO`).
- Adaptador temporário `LeituraDoHud` sobre `src/gameplay/game_session.gd` (Migration Plan passo 2), substituído quando os módulos reais existirem.
- `HudTuning` (17 campos, HU1–HU17) vem do catálogo validado; o formato `.tres` é entregue por `assets-e-conteudo`, a regra de validação por faixa mora no validador do Conteúdo.

---

## Out of Scope

- Story 002–005: regras de cada elemento (Vida, Fluxo/Esquiva/Fragmentos, fios/prompt/estados, Bloco do Pacto)
- Story 006: vista `Control`/`CanvasLayer`, âncoras e escala

---

## Files

- `src/presentation/ui/leitura_do_hud.gd` (novo)
- `src/presentation/ui/modelo_do_hud.gd` (novo)
- `src/presentation/ui/relogio_de_interface.gd` (novo)
- `src/presentation/ui/leitura_do_hud_sessao.gd` (adaptador temporário sobre `game_session.gd`)
- `src/content/hud_tuning.gd` (tipo do Resource, se o épico `conteudo` ainda não o criou)
- `tests/unit/hud/modelo_do_hud_leitura_test.gd`
- `tests/unit/hud/relogio_de_interface_test.gd`
- `tests/unit/hud/hud_tuning_validacao_test.gd`

Código atual: `src/presentation/game_hud.gd` não é reaproveitado aqui (lê `game_session` direto e guarda estado); `game_session.gd` só é lido pelo adaptador temporário.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/hud/modelo_do_hud_leitura_test.gd`, `relogio_de_interface_test.gd`, `hud_tuning_validacao_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/hud/modelo_e_vida_hud_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/` (story que entrega `EstadoDeJogo` e a entrega da lista de eventos à Apresentação); `production/epics/conteudo/` (story do validador por tipo/faixa); `production/epics/assets-e-conteudo/story-001-manifesto-e-tunings-da-fatia.md` (`HudTuning` .tres)
- Unlocks: `production/epics/hud/story-002-vida-segmentos-racha-e-vida-baixa.md`, `story-003-fluxo-esquiva-fragmentos-e-glifos.md`, `story-004-fios-prompt-chefe-e-visibilidade.md`, `story-005-bloco-do-pacto.md`
