# Story 005: Bloco do Pacto — modelo (existência, posição, F8, estados e eventos)

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R15–R19, F8, Edge Cases do Bloco do Pacto)
**Requirement**: `TR-hud-013`, `TR-hud-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisão 10); ADR-0002: Canal de eventos
**ADR Decision Summary**: `ModeloDoBlocoDoPacto` (RefCounted) lê `LeituraDoHud.estado_pacto(player_id)` em toda entrega e na criação; usa `troca_feita`, `troca_indisponivel`, `maldicao_exausta`, `maldicao_pronta` só para animar. Grupo próprio fora de container, 332 × 88 a 100%, 12 px acima do topo do grupo do jogador; só existe com Pactos.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0002 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `estado_pacto()` é consulta pura (Maldições R19); o adaptador real reaproveita o dicionário.

**Control Manifest Rules (Presentation)**:
- Required: HUD lê valores por consulta em toda entrega e na criação
- Forbidden: o HUD decidir as condições da troca (lê `troca_disponivel`)
- Guardrail: sem `_process` por elemento

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md`:*

- [x] AC-HD-38 [L] R15 — sem Pactos ou dupla vazia: bloco não existe, sem erro; 1 Maldição: sem Reserva nem Selo, placa 228 × 88.
- [x] AC-HD-39 [L] R15 — grupo y 922–1032: bloco x 48–380, y 822–910; topo do grupo em 880 → bloco 780–868.
- [x] AC-HD-40 [L] F8 — Baluarte 68/135: 14 segmentos, 6 cheios, 7º a 0,8, "68/135"; opção 8 desligada: sem número.
- [x] AC-HD-41 [L] F8/R17 — Exausta 210/600 → anel 0,65; Soberano 240/480 → 0,50; Pronta: anel some, silhueta cheia.
- [x] AC-HD-42 [L] F8/R17 — recarga 90/240 → setor 0,375 e Selo em contorno; `troca_disponivel` verdadeiro → Selo cheio; Saltando → contorno.
- [x] AC-HD-43 [L] R18 — `troca_indisponivel`: sacudida 4 px / 0,15 s, uma por evento; dois em 0,1 s reinicia sem passar de 4 px; redução de movimento: pulso do contorno, deslocamento 0.
- [x] AC-HD-44 [L] R18 — `troca_feita(automatica)` com Vida 0: no mesmo passo os slots trocam, Reserva Exausta em contorno com anel 0.
- [x] AC-HD-45 [L] R17 — duas Exaustas (300 e 120 de 600): Campo mostra a de 120 (anel 0,80), Reserva a de 300 (0,50).
- [x] AC-HD-46 [L] R19 — recriar com (Ativa 60/95; Exausta 210/600) e recarga 90: valores sem evento; Selo mostra "R" no teclado e LT no gamepad; troca de dispositivo troca o glifo no passo seguinte.

---

## Implementation Notes

*Derived from ADR-0012 §10:*

- Frações F8 limitadas a [0, 1]; denominador 0 → 0 sem erro (validação é do Conteúdo, ML2). `total_exausta` lido da fonte, nunca 600 fixo.
- Ancoragem dinâmica: o modelo recebe o retângulo do topo do grupo (da story 006) e calcula o y com `pacto_intervalo_px` × escala.
- Vínculo e técnica pronta não são peças separadas (decisão 10).
- Espécie sem silhueta: contorno genérico e aviso no log; o bloco segue.

---

## Out of Scope

- Story 006: desenho do bloco e captura AC-HD-47
- `production/epics/assets-e-conteudo/story-007-arte-de-maldicoes-e-chefe.md`: silhuetas de HUD por espécie

---

## Files

- `src/presentation/ui/modelo_do_bloco_do_pacto.gd` (novo)
- `tests/unit/hud/bloco_do_pacto_test.gd`

Código atual: não existe na fatia; nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/hud/bloco_do_pacto_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/hud/bloco_do_pacto_e_vista_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md`; `production/epics/maldicoes/` (story que entrega `estado_pacto()` e os eventos `troca_*`)
- Unlocks: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`
