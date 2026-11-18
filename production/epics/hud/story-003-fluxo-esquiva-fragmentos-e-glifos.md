# Story 003: Fluxo, Esquiva, Fragmentos e glifos por dispositivo

> **Epic**: HUD
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` (R6, R7, R8, R10 glifo, F4, F5, F6)
**Requirement**: `TR-hud-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0006: Input por passo
**ADR Decision Summary**: Glifos de prompt, Selo e menus vêm de `rotulo_acao(acao, dispositivo)` (`{texto, glifo}`), reconsultado quando o dispositivo ativo muda (troca no passo seguinte). Separador de milhar por `FormatoNumerico` próprio. Eventos (`selo_sem_fluxo`, `esquiva_sem_carga`, `saldo_mudou`) só animam; valores por consulta.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: eventos de mouse/teclado identificados pela classe, não por `device == 0` (4.7) — relevante só no provedor de Input, não aqui.

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; todo texto visível é chave de tradução
- Forbidden: a UI ler `Input`/`InputEvent`; string literal de interface em `.gd`
- Guardrail: `Label.text` só muda quando o valor muda

---

## Acceptance Criteria

*From GDD `design/gdd/hud.md`:*

- [x] AC-HD-10 [L] F4/R6 — Fluxo 39 Sem Fluxo; 40 Pronto; entalhe a 0,40; gota 24 px com 50; Fluxo 100 com recarga > 0: Em recarga.
- [x] AC-HD-11 [L] R6 — `selo_sem_fluxo`: um pisca por evento; segurar não gera evento novo.
- [x] AC-HD-12 [L] F5/R7 — 2 de 3 cargas, recarga 0,5: chevrons 1 e 2 cheios, 3º a 50%; `esquiva_sem_carga` estremece 80 ms.
- [x] AC-HD-32 [L] R7 — máximo 2 → 3: aparece o 3º chevron vazio, sem animação de recarga.
- [x] AC-HD-13 [L] F6/R8 — +2 e, 1 s depois, +3 → "+5" por 1,5 s após o último; ganho após 1,5 s abre "+N" novo.
- [x] AC-HD-14 [L] R8 — saldo 1 234 mostra "1 234"; delta < 0 mostra "−N"; sem `saldo_mudou` não pisca.
- [x] AC-HD-18 [L] R10 — trocar teclado → gamepad troca o glifo do prompt e do Selo no passo seguinte.

---

## Implementation Notes

*Derived from ADR-0012 §2, §9:*

- `ModeloDoFluxo`, `ModeloDaEsquiva`, `ModeloDosFragmentos` (RefCounted) dentro do `ModeloDoHud`; estados do Fluxo com precedência de Em recarga.
- "+N": janela em `t_ui` (`janela_ganho_s`), soma de deltas > 0, teto 99 999; pausa não consome a janela (já coberto pelo relógio, story 001).
- `FormatoNumerico.milhar(n)` próprio (a referência da engine não cobre locale numérico).
- Glifos: o modelo guarda o último dispositivo lido e reconsulta `rotulo_acao` ao mudar.

---

## Out of Scope

- Story 004: prompt de interação (posição/alcance) — esta story só cobre o glifo
- Story 006: desenho

---

## Files

- `src/presentation/ui/modelo_do_fluxo.gd`, `modelo_da_esquiva.gd`, `modelo_dos_fragmentos.gd` (novos)
- `src/presentation/ui/formato_numerico.gd` (novo)
- `tests/unit/hud/fluxo_esquiva_fragmentos_test.gd`
- `tests/unit/hud/glifo_por_dispositivo_test.gd`

Código atual: `game_hud.gd` (texto fixo de controles) — substituir por `rotulo_acao` (Migration Plan passo 5).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/hud/fluxo_esquiva_fragmentos_test.gd`, `tests/unit/hud/glifo_por_dispositivo_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/hud/fluxo_esquiva_fragmentos_fios_chefe_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md`; `production/epics/input/` (story que entrega `rotulo_acao` e o dispositivo ativo)
- Unlocks: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`
