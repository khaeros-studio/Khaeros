# Story 004: Fios de Vida, prompt de interação, barra de chefe e visibilidade por estado

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R9, R10, R11, R12, F7, Edge Cases); `design/ux/hud.md` §E, §L
**Requirement**: `TR-hud-009`, `TR-hud-005` (sinais `preco_revelado`/`tela_fechada` e visibilidade pelo estado de jogo)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0007: Cena, viewport e câmera
**ADR Decision Summary**: Fio e prompt ficam na camada UI, subárvore `Mundo`, posicionados por `compositor.mundo_para_vista(X)`; pool de 9 fios; visibilidade lida de `estado_de_jogo()`; fios e prompt voltam em `tela_fechada`. Barra de chefe entra no MVP (decisão 10): `ModeloDaBarraDeChefe` lê `chefe()`; o chefe não tem fio.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0007 2026-11-14

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: posição de mundo → vista pelo compositor do ADR-0007 (mesmas posições interpoladas do render); nunca `get_global_mouse_position()`.

**Control Manifest Rules (Presentation)**:
- Required: HUD lê por consulta; sinais Godot só em nós de Apresentação, conectados pelo `Main`
- Forbidden: guardar estado de jogo
- Guardrail: pool fixo de 9 fios (draw calls de UI ≤ 80)

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md` e `design/ux/hud.md` §L:*

- [x] AC-HD-15 [L] F7/R9 — Vida 12/40: fio a 30%; invisível antes do 1º dano; some 120 passos após o último; reinicia a cada dano; elite 1,5×.
- [x] AC-HD-16 [L] R9 — inimigo morto: fio some no mesmo passo.
- [x] AC-HD-29 [L] R9 — 9 fios com 9 feridos; um 10º mostra os 9 mais próximos; elite 5/100 → 5%, 1,5×.
- [x] AC-HD-30 [L] R9 — dano do Selo e de status (sem `acerto`) faz o fio aparecer.
- [x] AC-HD-17 [L] R10 — prompt a 111 px do centro aparece, a 112 px não; some na Bênção e na Transição; sem prompt na pedra do santuário.
- [x] AC-HD-19 [L] R12 — Bênção: grupo e Fragmentos visíveis, fios e prompt ocultos; Pausa: 60%; Transição: fade 0,25 s (≤ 300 ms com redução de movimento).
- [x] AC-HD-36 [L] R12 — `tela_fechada` reexibe fios (janela ainda válida) e prompt (porta ainda interagível) no mesmo passo; sem o sinal, não voltam. Vale também para a tela de consentimento (UX hud §L).
- [x] AC-HD-33 [L] R12 — telas de início e final e estado Encerrada: nenhum elemento de combate.
- [x] AC-HD-20 [L] R11 — sem chefe, a barra não existe na cena e não há erro; UX hud §L: na câmara do chefe a barra aparece com o chefe vivo e some em `Morto`/`Subjugado`; o chefe não tem fio.

---

## Implementation Notes

*Derived from ADR-0012 §1, §2, §10:*

- `ModeloDosFios`: lê `inimigos_feridos()` (Vida caiu → janela `fio_visivel_s` em passos); ignora `chefe_id`; ordena por distância ao jogador e corta em 9.
- Prompt: só lê `porta_interagivel(player_id)`; o HUD não tem raio próprio (Câmaras R13 decide o alcance).
- `ModeloDaBarraDeChefe`: lê `chefe()` em toda entrega; eventos `chefe_subjugado`/`chefe_escolhido` só animam.
- Visibilidade: mapa `EstadoDeJogo → {grupo, fragmentos, fios, prompt, opacidade}`; `oferta_aberta` esconde, `tela_fechada` reexibe.

---

## Out of Scope

- Story 006: nós `Control` da subárvore `Mundo` e captura de tela
- Épico `chefes`: o modelo de fases do chefe (aqui só a leitura)

---

## Files

- `src/presentation/ui/modelo_dos_fios.gd`, `modelo_do_prompt.gd`, `modelo_da_barra_de_chefe.gd`, `visibilidade_do_hud.gd` (novos)
- `tests/unit/hud/fios_e_prompt_test.gd`
- `tests/unit/hud/visibilidade_por_estado_test.gd`
- `tests/unit/hud/barra_de_chefe_test.gd`

Código atual: o desenho de prompt/fios em `game_hud.gd` e `world_view.gd` é referência apenas; substituir.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/hud/fios_e_prompt_test.gd`, `visibilidade_por_estado_test.gd`, `barra_de_chefe_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/hud/fluxo_esquiva_fragmentos_fios_chefe_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md`; `production/epics/cena-e-camera/` (story de `mundo_para_vista`); `production/epics/camaras-e-ondas/` (story da porta interagível, Câmaras R13)
- Unlocks: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`
