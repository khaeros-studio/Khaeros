# Story 010: Apresentação do chefe — impact frame, luz, Fase 2, contorno secundário e áudio

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature (consumo na Apresentação)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (Visual/Audio Requirements CH-V1–CH-V4, CH-A1; Game Feel; R11)
**Requirement**: `TR-chefes-016`, `TR-chefes-006` (desenho do contorno secundário tracejado)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0016: Áudio: ganchos e vozes; ADR-0014 (contorno secundário só desenho)
**ADR Decision Summary**: impact frame de chefe com preempção, luz de chefe e leitura da Fase 2 pelo pipeline (material por entidade, relógio `t_apres`); contorno tracejado por `raio_secundario_px` é só desenho; ganchos `chefe_*` saem da lista de eventos do passo para o áudio (`SomDef`, `AudioTuning`).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: ADR-0011 — shaders/LUT/passes de tela com verificação pendente em 4.7.2 (EX-0011 E1–E3); ADR-0016 — barramentos e pool de vozes (MEDIUM).

**Control Manifest Rules (this layer)**:
- Required (Presentation): a Apresentação lê a lista de eventos e vistas; nunca escreve estado de jogo
- Forbidden: o contorno secundário participar do teste de acerto

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] CH-V1/CH-V2: silhueta ~1,8× o Iniciado (`raio_px` 45), coroa magenta, arena com névoa aberta e 4 pilares escuros.
- [x] CH-V3: no 1º passo de `TransicaoFase`, anel de tinta e osso até 240 px; na Fase 2, rachaduras magenta contínuas e rastro curto.
- [x] CH-V4: impact frame em Osso (`impact_chefe_s`); em Pactos o chefe cai num joelho com halo de Osso; abatido/exorcizado, o magenta se desfaz em partículas.
- [x] Contorno tracejado de 420 px no telégrafo do Padrão 3 (só desenho); ganchos de áudio `chefe_surgimento`, `chefe_preparo_garra`, `chefe_avanco_irrupcao`, `chefe_pulso_soberania`, `chefe_convergencia_puxao`, `chefe_transicao_furia`, `chefe_subjugado`, `chefe_derrotado` disparam nos eventos certos.

---

## Implementation Notes

*Derived from ADR-0011/0016:*

- Sign-off do lead visual em `production/qa/evidence/chefes-apresentacao-evidence.md`; capturas de cada estado acima.

---

## Out of Scope

- Story 007: barra de chefe.
- Épico `assets-e-conteudo`: arte final do Soberano.

---

## Files

- `src/presentation/world_view.gd` (**adaptar**: chefe, contorno secundário, leitura da Fase 2)
- `src/presentation/` (impact frame/luz de chefe, conforme o épico `pipeline-visual`; ganchos no épico `audio`)
- `production/qa/evidence/chefes-apresentacao-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas em `production/qa/evidence/` + sign-off em `production/qa/evidence/chefes-apresentacao-evidence.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-008-queda-do-chefe-e-limpeza.md`; épicos `production/epics/pipeline-visual/EPIC.md`, `production/epics/audio/EPIC.md`, `production/epics/feedback-de-combate/EPIC.md` (impact frame)
- Unlocks: None

**Código da fatia**: `src/presentation/world_view.gd` — **adaptar** (redesenho de telégrafos com dimensões gravadas deve sair, ADR-0014).
