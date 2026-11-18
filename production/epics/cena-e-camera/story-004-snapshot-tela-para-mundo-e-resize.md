# Story 004: Snapshot tela → mundo (F6), injeção e resize

> **Epic**: Cena 3/4 e câmera
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/cena-3-4-e-camera.md`
**Requirement**: `TR-cena-010`, `TR-cena-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Cena, viewport e câmera (com ADR-0006 para o consumo pelo Input)
**ADR Decision Summary**: O Input consulta um instantâneo de `pos` do último render, com a geometria vigente, sem impulsos, chute, tremor nem zoom; três espaços explícitos (Janela, Vista lógica, Mundo); câmera, impulsos e relógio são injetados para permitir câmera falsa.
**ADR Version**: 2026-11-14

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: `InputEvent.position` pode chegar transformado pelo viewport; a integração deve verificar o espaço do evento em janela real e inverter só a transformação de stretch correspondente. Sem verificação em janela real, o item fica NOT ASSESSED, não aprovado.

**Control Manifest Rules (this layer)**:
- Required: duas bases (`pos`, `pos_seguir`) e snapshot explícito para o Input; adaptador normaliza eventos para o espaço Janela uma vez (ADR-0007)
- Forbidden: aplicar a escala F6 duas vezes; converter pelo canvas com tremor; `get_global_mouse_position()` (ADR-0007)
- Guardrail: a consulta não recalcula a câmera

---

## Acceptance Criteria

*From GDD `design/gdd/cena-3-4-e-camera.md`, scoped to this story:*

- [ ] **AC-05** F6: 1280×720, mouse (960,180), C = (1500,800) → (1980,530); 3840×1080, mouse (1920,540) → C e mouse na faixa em (100,540) → x = C.x − 1290; 1440×1080, mouse (720,540) → C e (720,50) → y = C.y − 540
- [ ] **AC-06** Câmera falsa com chute de 40 px, tremor e zoom de 1,15 → tela → mundo idêntico ao da câmera sem impulsos
- [ ] **AC-37** Câmera falsa com `pos` do último render (960,540), P_anterior (0,0), P_atual (33,0), f_i 0,5, janela 1920×1080 e cursor em (960,540) → o Input recebe a mira (927,540) como vetor bruto antes de normalizar, medida a partir de `P_atual` e não (943,5; 540)
- [ ] **AC-04** (Integration) Ultrawide com câmara de 2880 e câmera encostada à esquerda → a janela muda para 16:9 → no quadro do `size_changed`, W = 1920 e `pos` já está presa pela F4, sem suavização; **[M]** alternar tela cheia

---

## Implementation Notes

*Derived from ADR-0007 §3 e Key Interfaces:*

`tela_para_mundo(cursor_janela) -> Vector2` usa o último snapshot base válido. Espaços: Janela (pixels locais da área de conteúdo, inclui faixas), Vista lógica `(cursor_janela − origem)/f` presa a `[0,W]×[0,1080]` sobre a faixa, Mundo `pos + cursor_logico − Vector2(W/2,540)` (substituir `pos` por `pos_seguir` só no lookahead). A origem do vetor de ataque continua sendo `P_atual` de física. Exceção em resize/corte: ambos publicam imediatamente a base coerente com a nova geometria e a câmara, presa sem suavização, inclusive em Pausa. A interface de conversão é injetada no provedor de Input (Input, story 003); testes usam câmera falsa.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Épico input, story 003: a mira F4 que consome a conversão
- Story 006: corte atômico

---

## Files

- `src/foundation/cena/conversor_tela_mundo.gd` (interface injetável)
- `src/foundation/cena/camera_de_apresentacao.gd` (snapshot)
- `tests/unit/cena/tela_para_mundo_test.gd`
- `tests/unit/cena/doubles/camera_falsa.gd`
- `tests/integration/cena/resize_ultrawide_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/cena/tela_para_mundo_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/cena-e-camera/story-001-geometria-de-viewport-e-project-godot.md`, `production/epics/cena-e-camera/story-002-limites-da-camara-e-camera-tuning.md`, `production/epics/input/story-003-mira-fonte-e-ponto-de-mira.md`
- Unlocks: None

## Completion Notes

**Arquivos**: `src/foundation/cena/conversor_tela_mundo.gd` (`@abstract`, com a F6 estática `converter`); snapshot em `camera_de_apresentacao.gd` (`tela_para_mundo`, `definir_geometria`); `tests/unit/cena/tela_para_mundo_test.gd` (6 casos, passam); `tests/unit/cena/doubles/camera_falsa.gd`; `tests/integration/cena/resize_ultrawide_test.gd` (2 casos, passam).

- AC-05 coberto. AC-06: a câmera real com chute de 40, tremor e zoom 1,15 dá a mesma conversão que a câmera sem impulsos. AC-37: a mira bruta (927,540) é medida a partir de `P_atual`.
- AC-04: o resize prende `pos` e `pos_seguir` pela F4 com o novo W no mesmo quadro, sem suavização, inclusive em Pausa. Janela de tamanho zero mantém a geometria anterior. Pela F4 a borda esquerda presa é sempre x0 + 960, para qualquer W; por isso o teste confere a imediatez e o W, não um salto.
- **Pendências**: [M] alternar tela cheia. O espaço real de `InputEvent.position` sob stretch/DPI fica **NOT ASSESSED** (precisa de janela real). Falta injetar `ConversorTelaMundo` no provedor de Input (épico input, story 003).
- Execução: `godot --headless -s -d ... GdUnitCmdTool.gd -a res://tests/unit/cena -a res://tests/integration/cena --ignoreHeadlessMode` (Godot 4.7.2) → 61 casos no épico, 0 falhas, 0 erros, 0 órfãos, sem erro de parse.
- Pendência comum do épico: `src/app/main.gd` e `src/presentation/world_view.gd` ainda usam `src/presentation/game_camera.gd`, que foi mantido (o orquestrador não autorizou editar esses arquivos). Migrar para `CameraDeApresentacao` e apagar `game_camera.gd` fica para o épico orquestrador-do-passo / story 008.
- Esquema `CameraTuning` duck-typed (lido por `Object.get`): `meia_vida`, `lookahead_max`, `raio_mouse`, `teto_deslocamento`, `teto_zoom`, `limiar_descarte`, `max_impulsos`, `presets_impulso` (nome → objeto com `meia_vida`, `chute`, `tremor`, `zoom`), `camara_minima`/`camara_maxima`. O épico conteudo deve adotar esses nomes ou avisar.
