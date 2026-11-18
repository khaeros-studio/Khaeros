# Story 007: Opções de acessibilidade do HUD — aplicação e persistência

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R13, UI Requirements); `design/ux/hud.md` §J, §K
**Requirement**: `TR-hud-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 8 e 10); ADR-0013: Persistência do MVP
**ADR Decision Summary**: Escala, número de Vida, Vida colorida, alto contraste e vinheta ficam em `user://opcoes.cfg` seção `[ui]` (`escala`, `numero_vida`, `vida_colorida`, `alto_contraste`, `vinheta`), pelo `RepositorioDeOpcoes` injetado; a UI recebe os valores e não lê arquivo; aplicam os donos (HUD, Pipeline). Falha ao gravar: a UI mostra `OPCOES_FALHA_GRAVAR` uma vez por tentativa e segue com o valor em memória.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0013 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ConfigFile/FileAccess em `user://`, ADR-0013)
**Engine Notes**: gravação atômica com `.bak` é do repositório (épico persistencia); aqui só a aplicação.

**Control Manifest Rules (Presentation)**:
- Required: todo texto visível é chave de tradução
- Forbidden: o Feedback aplicar opção diretamente (pede aos donos); a UI ler arquivo
- Guardrail: persistência só por ação fora do passo

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md`:*

- [x] AC-HD-25 [L] R13 — opção 9 troca o osso por vermelho-tinta; opção 10 liga placas a 100%; opção 8 desliga o número de Vida; opção 5 deixa a vinheta estática; opção 6 a 50% reduz a opacidade da vinheta pela metade; 9 e 10 juntas valem as duas.
- [x] TR-hud-012 — mudar escala para 150% e reiniciar mantém 150% (`[ui] escala`); idem para as demais chaves `[ui]` (fake de `RepositorioDeOpcoes` com ida e volta).
- [x] Falha de gravação simulada mostra `OPCOES_FALHA_GRAVAR` uma vez e a sessão segue com o valor em memória.

---

## Implementation Notes

*Derived from ADR-0012 §8, §10:*

- `OpcoesDoHud` (RefCounted) montado a partir do `RepositorioDeOpcoes`; o `Main` injeta no `ModeloDoHud` e reaplica ao mudar.
- Alto contraste troca o tema; Vida colorida vale só para a Vida do jogador (barras de Maldição continuam em osso).

---

## Out of Scope

- Story 009: a tela de opções que edita esses valores
- `production/epics/persistencia/`: `RepositorioDeOpcoes` e gravação atômica

---

## Files

- `src/presentation/ui/opcoes_do_hud.gd` (novo)
- `src/presentation/ui/modelo_do_hud.gd`, `vista_do_hud.gd` (adaptar)
- `tests/integration/hud/opcoes_do_hud_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/hud/opcoes_do_hud_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/hud/bloco_do_pacto_e_vista_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`; `production/epics/persistencia/` (story do `RepositorioDeOpcoes`)
- Unlocks: `production/epics/hud/story-009-tela-de-opcoes.md`
