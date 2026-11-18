# Story 008: Portas no mundo — moldura, ícones e quantidade

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature (consumo na Apresentação)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (Visual/Audio Requirements, UI Requirements, Game Feel)
**Requirement**: `TR-portas-008` (lado consumidor: a vista lê `EvPortaEscolhida`/`VistaDePorta`), `TR-portas-002` (portas só aparecem depois da Bênção)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0012: UI e HUD; ADR-0002: Canal de eventos
**ADR Decision Summary**: a Apresentação só lê a lista de eventos do passo e vistas publicadas; material por entidade com relógio `t_apres`; o aviso "Interagir" é do HUD (Control em CanvasLayer).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: ADR-0011 — shaders/LUT com verificação pendente em 4.7.2 (EX-0011 E1–E3 antes das stories do Pipeline). Usar só o que o ADR-0011 marca verificado.

**Control Manifest Rules (this layer)**:
- Required (Presentation): a Apresentação lê `EventoDoPasso`/vistas e nunca escreve estado de jogo
- Forbidden: regra lendo o resultado do RNG cosmético
- Guardrail: vistas pré-alocadas, sem alocação por quadro

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-21** Captura com 2 e 3 portas abertas: os ícones se distinguem por forma e valor em tons de cinza e nos 3 simuladores de daltonismo; a quantidade é legível.
- [x] **AC-PR-22** Registro com testador, build e contagem: ≥ 80% dizem o que cada porta dá antes de entrar (proposta; registro manual em `production/qa/evidence/`).
- [x] Ícones distintos para bênção, Fragmentos, cura, santuário e chefe; moldura acesa aberta / tinta apagada fechada (Visual/Audio Requirements).

---

## Implementation Notes

*Derived from ADR-0011/0012:*

- `world_view.gd` desenha as portas a partir de `VistaDePorta`; nenhum cálculo de regra na vista.
- Arte final depende de `/asset-spec system:portas-e-recompensas`; placeholder com forma distinta é aceitável para a captura se respeitar forma + valor.

---

## Out of Scope

- Épico `hud`: aviso "Interagir" e ganho de Fragmentos/Vida.
- Épico `audio`: sons de conceder e estalo.

---

## Files

- `src/presentation/world_view.gd` (adaptar: desenhar portas)
- `production/qa/evidence/portas-no-mundo-evidence.md` + capturas (2 e 3 portas, cinza, 3 simulações de daltonismo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas em `production/qa/evidence/` + sign-off em `production/qa/evidence/portas-no-mundo-evidence.md`.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-007-escolha-da-porta.md`; épico `production/epics/pipeline-visual/EPIC.md`
- Unlocks: None

**Código da fatia**: `src/presentation/world_view.gd` — **adaptar** (acrescentar o desenho das portas lendo vistas; não acoplar a `GameSession`).
