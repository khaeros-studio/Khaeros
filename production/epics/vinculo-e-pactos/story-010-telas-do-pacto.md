# Story 010: Telas do pacto — Escolha do Pacto, Primeiro Vínculo, consentimento, Pactuar/Exorcizar e painel final

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature (vista na Apresentação)
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (§ UI Requirements; AC-VP-26)
**Requirement**: `TR-vinculo-003` (tela), `TR-vinculo-008` (telas no estado Bênção), `TR-vinculo-011` (tela do chefe) — parte visual
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD
**ADR Decision Summary**: `Control` em `CanvasLayer`, foco duplo próprio, escala 85–150%, entrada só por `ComandosDeTela`, texto por chave de tradução; Bloco do Pacto e tela de consentimento previstos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0012: foco duplo do 4.6 — não usar `Button` nativo com foco da engine; `mouse_filter = MOUSE_FILTER_IGNORE`.

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; animações por `t_ui`/`t_real`; todo texto é chave de tradução
- Forbidden: ler `Input`/`InputEvent`; string literal de interface; `Timer`/`Tween` sem controle de pausa; chamar `play()`
- Guardrail: UI ≤ 80 draw calls

---

## Acceptance Criteria

*From GDD § UI Requirements (verificação manual) e AC-VP-26:*

- [x] Escolha do Pacto (V16): cartões das pactuadas (nome, raridade em texto e ícone, nível, barra até o próximo nível, kit em 3–5 linhas, memórias), slots "Campo" e "Reserva", Confirmar/Voltar, teclado, mouse e gamepad; pulada com 0 ou 1 pactuada.
- [x] Cartão "O Primeiro Vínculo" (V3) e prompt Interagir com `rotulo_acao("interagir")`.
- [x] Consentimento (V10, V11): nome, raridade, memória revelada, botões do caso ("Oferecer o vínculo"/"Deixá-la ir", "Reafirmar o vínculo (+6)"/"Deixá-la ir" ou só "Ela voltará"); sem tempo limite.
- [x] Pactuar/Exorcizar (V18): "Pactuar: 0 Fragmentos" + ganho de vínculo; "Exorcizar: +6 Fragmentos"; caso V18.5 mostra o destino dos pontos ou "O vínculo já está inteiro". Painel final com pontos por fonte, barra animada e "Nível N!".
- [x] Acessibilidade: raridade e estado nunca só por cor; texto em todos os botões; barras com número (`114/114`).
- [x] AC-VP-26 (playtest): em 5 playtesters na 1ª run de Pactos, ≥ 4 protegem o *Espreitador* na 1ª tentativa e descrevem o pacto como "conquistado"; nenhum diz "sem chance".

---

## Implementation Notes

- Telas leem o Vínculo por consulta e mandam a escolha como evento de UI fora do passo (ADR-0015 §5).

---

## Out of Scope

- VP-V1–VP-V5 (acuada, fuga, fio nascendo, amarras) e VP-A1: épicos `production/epics/pipeline-visual/`, `production/epics/feedback-de-combate/`, `production/epics/audio/`.

---

## Files

- `src/presentation/ui/pacto/tela_escolha_do_pacto.gd`, `tela_consentimento.gd`, `tela_chefe_pactuar.gd`, `painel_vinculo_final.gd` (+ `.tscn`)
- `production/qa/evidence/vinculo-telas-do-pacto/` (screenshots) e `production/qa/evidence/vinculo-playtest-ac-vp-26.md`

Código da fatia: `src/presentation/game_hud.gd` não é estendido aqui (telas novas seguem o ADR-0012).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshot retido de cada tela em `production/qa/evidence/vinculo-telas-do-pacto/`; relatório de playtest para AC-VP-26
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-003-primeiro-pacto-e-escolha-da-dupla.md`, `production/epics/vinculo-e-pactos/story-006-consentimento-portas-e-dupla.md`, `production/epics/vinculo-e-pactos/story-008-chefe-pactuar-ou-exorcizar.md`; épicos `production/epics/hud/`, `production/epics/tela-de-bencao-e-carta/` (base de telas do ADR-0012)
- Unlocks: None
