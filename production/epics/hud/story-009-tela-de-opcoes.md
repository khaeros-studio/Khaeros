# Story 009: Tela de opções — escala, HUD, remapeamento, telemetria e reset do perfil

> **Epic**: HUD (escolhido por ser o dono do TR das opções do HUD; spec `design/ux/pausa-e-opcoes.md`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/hud.md` R13; `design/gdd/input-e-controle.md` R8, R10 (remapeamento); `design/gdd/save-e-perfil.md` R11, UI Requirements; UX: `design/ux/pausa-e-opcoes.md` §5–§14
**Requirement**: `TR-hud-012` (superfície de edição). TRs de outros épicos que esta tela exibe (continuam lá): TR-save-014, TR-save-018 (`persistencia`), remapeamento (`input`).
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 8, 10); ADR-0013: Persistência do MVP; ADR-0006: Input por passo
**ADR Decision Summary**: A tela de opções edita `[ui]` e `[telemetria]` pelo `RepositorioDeOpcoes`; avisos `PERFIL_*` só fora de Jogo, uma vez por sessão, navegáveis; reset com duas confirmações, "Cancelar" padrão, desabilitado com motivo no modo Sem gravação. Remapeamento usa o contexto de captura do Input e `t_real`.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0013 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: E2 (esvaziar ações nativas sem quebrar `LineEdit`) — NOT SOURCEABLE, depende de EX-0012-E2.

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; todo texto visível é chave de tradução
- Forbidden: a UI ler arquivo de opções/perfil; `Button` nativo com foco da engine
- Guardrail: gravação só por ação fora do passo

---

## Acceptance Criteria

*From `design/ux/pausa-e-opcoes.md` §14 (spec In Review):*

- [x] Remapear `ataque` para a tecla do `especial` troca os dois e mostra `INPUT_CONFLITO_TROCA`; fechar e reabrir mantém os binds.
- [x] Mudar a escala para 150% reposiciona o HUD na hora; reiniciar mantém 150% (`[ui] escala`).
- [x] "Apagar progresso de pactos" só fica ativo no menu principal, pede duas confirmações e cria `perfil.cfg.reset.bak`.
- [x] Nenhum aviso `PERFIL_*` aparece durante `JOGO`; todos são dispensáveis com B/Esc.
- [x] Todo o fluxo é concluído só com gamepad.

---

## Implementation Notes

*Derived from ADR-0012 §8, §10 e ADR-0013 §8:*

- `ModeloDasOpcoes` sobre `ModeloDeFoco`; cada mudança chama o repositório e reaplica nos donos (HUD story 007, Pipeline).
- Telemetria: `[telemetria] ligada`/`aviso_visto`, "abrir pasta" e "apagar dados" (ADR-0013).
- Chaves `OPCOES_*`, `PERFIL_*`, `INPUT_*`.

---

## Out of Scope

- Story 008: o menu de pausa em si
- `production/epics/input/`: a captura e a regra de conflito (aqui só a tela)

---

## Files

- `src/presentation/ui/modelo_das_opcoes.gd`, `vista_das_opcoes.gd`, `scenes/ui/opcoes.tscn` (novos)
- `tests/unit/hud/modelo_das_opcoes_test.gd`
- `production/qa/evidence/opcoes-ui.png`, `opcoes-remap.png`, `opcoes-reset-perfil.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshots de cada aba/estado em `production/qa/evidence/`
**Status**: [x] Complete (`tests/unit/hud/pausa_opcoes_e_fim_de_run_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-007-opcoes-de-acessibilidade-do-hud.md`; `production/epics/hud/story-008-menu-de-pausa-abandono-e-seed.md`; `production/epics/input/` (remapeamento e contexto de captura); `production/epics/persistencia/` (repositórios, reset do perfil); `production/epics/experimentos-de-engine/` (EX-0012-E2)
- Unlocks: None
