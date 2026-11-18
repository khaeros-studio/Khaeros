# Story 003: Modos de tela, PasseDeTela e relógios t_vivo/t_apres

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O `EstadoVisual` resolve o modo de tela por prioridade (Transição > Morte > Bênção > Impacto), o `PasseDeTela` (wipe/fade, progresso 0 → 1, avançado pelo orquestrador) e os valores dos relógios que o Pipeline escreve. Tudo testável com o orquestrador dublê.

**GDD**: `design/gdd/pipeline-visual.md` (§ States and Transitions, § F8. Relógios, R7, R11)
**Requirement**: `TR-pipeline-004`, `TR-pipeline-007` (modos e passes), `TR-pipeline-012` (parte lógica: Reduzir flashes / Redução de movimento)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: O orquestrador é dono dos valores (`t_vivo()`, `t_apres()`, `estado()`) e decide a Bênção; o `PasseDeTela` é objeto do Pipeline avançado pelo orquestrador com `min(delta, dt_max_apres)`, não lê `t_apres`; a LUT nova e o zero dos relógios saem na última das seis ações da Transição.
**ADR Version**: ADR-0011 2026-11-16; ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura. F8 exige float32 bit a bit (AC-PV-44): converter com `PackedFloat32Array` no oráculo.

**Control Manifest Rules (this layer)**:
- Required: `t_vivo` e `t_apres` escritos a partir do orquestrador, sem relógio próprio; LUT trocada e relógios zerados só na última das seis ações
- Forbidden: Never `fmod` nos relógios; never `SceneTree.paused`
- Guardrail: n/a (lógica pura)

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-35 [L] Estados — prioridade dos modos (Transição > Morte > Bênção > Impacto)
- [x] AC-PV-81 [L] Estados — impacto ativo cortado; a Bênção espera
- [x] AC-PV-41 [L] R7 — transição de câmara e fade (`progresso_wipe`)
- [x] AC-PV-65 [L] R7/F8 — o zero dos relógios não afeta o wipe
- [x] AC-PV-76 [L] Edge — opção de acessibilidade muda no meio da run
- [x] AC-PV-77 [L] Edge — pausa no meio do impact frame
- [x] AC-PV-43 [L] F8 — relógios por estado (orquestrador dublê)
- [x] AC-PV-44 [L] F8 — float32 e VV16
- [x] AC-PV-69 [L] R1/R7 — `modo_impacto` por shader (espelho)

---

## Implementation Notes

*Derived from ADR-0011 §1, §2, §7:*

- Interfaces: `trocar_regiao`, `definir_profundidade`, `definir_bencao` (o orquestrador decide; desliga em `tela_fechada`), `avancar_apres`, `globais_sujos() -> Dictionary` (limpa ao ler).
- O modo wipe ou fade é decidido no pedido e não muda durante o passe; Transição não aceita pausa (ADR-0001).
- `PasseDeTela.progresso() ≥ 0,5` é testado pelo orquestrador uma única vez (`troca_feita`).

---

## Out of Scope

- Story 005: a escrita real em globais/uniforms (`PipelineVisual.aplicar_quadro`)
- Story 010: impact frames vistos em captura

---

## Files

- `src/presentation/visual/estado_visual.gd`
- `src/presentation/visual/passe_de_tela.gd`
- `tests/unit/visual/modos_de_tela_passes_e_relogios_test.gd`

Código da fatia: `src/app/main.gd` usa `_process` com relógio próprio — **adaptar** no épico orquestrador-do-passo; aqui só o dublê do orquestrador.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/visual/modos_de_tela_passes_e_relogios_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/pipeline/modos_relogios_e_lut_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-001-visual-tuning-e-validacao.md`, `production/epics/pipeline-visual/story-002-limitador-de-flashes-f6.md`; épico `production/epics/orquestrador-do-passo/EPIC.md` (interface `t_vivo()/t_apres()/estado()`, só a assinatura para o dublê)
- Unlocks: `production/epics/pipeline-visual/story-005-escritor-de-globais-e-pipeline-visual.md`, `production/epics/feedback-de-combate/story-006-relogios-pausa-transicao-e-opcoes.md`
