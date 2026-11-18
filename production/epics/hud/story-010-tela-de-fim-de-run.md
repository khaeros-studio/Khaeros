# Story 010: Tela de fim de run — resumo, painel de vínculo, seed e Nova run

> **Epic**: HUD (escolhido porque o HUD R12 manda a tela final para fora do HUD de combate e esta é a outra tela de sessão; spec `design/ux/tela-fim-de-run.md`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` R4–R8, R7-P, R8-P; `design/gdd/vinculo-e-pactos.md` V17; `design/gdd/hud.md` R12 (sem HUD de combate na tela final); UX: `design/ux/tela-fim-de-run.md`
**Requirement**: `TR-hud-005` (visibilidade pelo estado de jogo: Encerrada sem HUD de combate). TRs exibidos que pertencem a outros épicos: TR-rng-012 (seed), resumo da run (`run-e-regioes`).
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 3, 11); ADR-0006: Input por passo
**ADR Decision Summary**: Telas finais são `Control` no `CanvasLayer` UI com `ModeloDeFoco` e `ComandosDeTela`; mostram a seed pronta de `LeituraDaRun.texto_seed()` e "Copiar seed" por `PortaDaAreaDeTransferencia`; entrada com barreira de contexto (botão segurado não conta). O `ResumoDaRun` vem do ADR-0015 por consulta.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: clipboard NEEDS VERIFICATION (mesma porta da story 008).

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; todo texto visível é chave de tradução
- Forbidden: a UI formatar a seed; literal de texto em `.gd`
- Guardrail: UI ≤ 80 draw calls

---

## Acceptance Criteria

*From `design/ux/tela-fim-de-run.md` §14 (spec In Review) e HUD AC-HD-33:*

- [x] A tela aparece em ≤ 500 ms após `run_encerrada` (vitória) ou após o fim do estado Morte.
- [x] Vitória de Lâmina mostra câmaras limpas = 7, bônus +15, sem painel de vínculo nem campo Dupla.
- [x] Morte em run de Pactos com pacto feito mostra o pacto no painel de vínculo e bônus "—".
- [x] Os 12 campos de R7-P aparecem com valores iguais ao `ResumoDaRun` registrado na telemetria.
- [x] Segurar Ataque durante a morte e soltar na tela não aciona "Nova run".
- [x] "Nova run" abre a Escolha de arma com a última arma em foco e seed diferente da anterior.
- [x] Copiar seed põe na área de transferência exatamente o texto do rodapé.
- [x] AC-HD-33 — na tela final nenhum elemento de combate do HUD é desenhado.
- [x] Toda a tela é operável só por gamepad e só por teclado.

---

## Implementation Notes

*Derived from ADR-0012 §3, §11:*

- `ModeloDoFimDeRun` lê `ResumoDaRun` por consulta (`LeituraDaRun`); nada é recalculado na UI.
- Chaves `RUN_*`; algarismos tabulares na linha da seed.

---

## Out of Scope

- Épico `run-e-regioes`: o `ResumoDaRun` e o estado `ENCERRADA`
- `production/epics/tela-de-bencao-e-carta/story-007-modo-arma-escolha-de-arma.md`: a Escolha de arma aberta por "Nova run"

---

## Files

- `src/presentation/ui/modelo_do_fim_de_run.gd`, `vista_do_fim_de_run.gd`, `scenes/ui/fim_de_run.tscn` (novos)
- `src/presentation/game_hud.gd` (remover telas de morte/vitória desenhadas à mão)
- `tests/unit/hud/fim_de_run_test.gd`
- `production/qa/evidence/fim-de-run-vitoria-lamina.png`, `fim-de-run-morte-pactos.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshots de vitória e de morte com Pactos em `production/qa/evidence/`
**Status**: [x] Complete (`tests/unit/hud/pausa_opcoes_e_fim_de_run_test.gd`, `production/qa/evidence/hud-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/hud/story-008-menu-de-pausa-abandono-e-seed.md` (porta de clipboard); `production/epics/tela-de-bencao-e-carta/story-001-modelo-de-foco-dados-da-carta-e-fileira.md`; `production/epics/run-e-regioes/` (`ResumoDaRun`, `ENCERRADA`); `production/epics/vinculo-e-pactos/` (painel de vínculo)
- Unlocks: None
