# Story 007: Modo arma — tela Escolha de arma com 3 cartas e aviso da Besta

> **Epic**: Tela de bênção e carta (a Escolha de arma reusa `CartaView` + `GrupoDeCartas`; spec `design/ux/tela-escolha-de-arma-e-pacto.md`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R15-P); `design/gdd/armas-das-doutrinas.md` R4, R8; UX: `design/ux/tela-escolha-de-arma-e-pacto.md`
**Requirement**: `TR-tela-bencao-014` (o TR-armas-004 fica no épico `armas-das-doutrinas`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisão 11, "Tela de escolha de arma"); ADR-0006: Input por passo
**ADR Decision Summary**: Mesmo `GrupoDeCartas`, `ModeloDeFoco` e `ComandosDeTela` no modo `arma`, 3 cartas (Lâmina, Ressonância, Besta do Vínculo), foco inicial na do meio, sem troca nem `preco_revelado`; `tela_fechada` emitido. Escolha por `PortaDaEscolhaDeArma.escolher(i)` (ligada pela composição da run, ADR-0015). `aviso_texto` preenchido por quem monta a carta da Besta quando o perfil não tem Maldição pactuada; o Armas monta os `DadosDaCarta` de arma.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: as mesmas da story 005 (E1/E2).

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; `CartaView` recebe `DadosDaCarta`
- Forbidden: string literal de interface; ler `perfil.cfg` na UI
- Guardrail: UI ≤ 80 draw calls

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md` e `design/ux/tela-escolha-de-arma-e-pacto.md` §14:*

- [x] AC-TB-36 [L] R15-P — 3 cartas de arma em modo arma: fileira 1 056 px a 100%, foco inicial 1, sem botão de troca; confirmar envia `escolher(i)` e `tela_fechada`, sem `preco_revelado`.
- [x] AC-TB-37 [L] R15-P — Besta com `aviso_texto`: aviso na faixa 76–92%, altura igual; nulo: faixa vazia de osso; carta de bênção com `aviso_texto` nulo desenha igual à de antes da emenda.
- [x] AC-TB-38 [UI] R15-P — captura retida da Escolha de arma com 3 cartas, com e sem o aviso na Besta.
- [x] UX §14 — interativa (fim da trava) em ≤ 950 ms após "Jogar"; com `ultima_arma = ressonancia` o foco abre na Ressonância, sem arquivo na Lâmina; Besta sem Maldição mostra o aviso sem magenta; concluída só com gamepad e só com teclado.

---

## Implementation Notes

*Derived from ADR-0012 §10, §11:*

- `abrir(cartas, 0, t, &"arma")`; nenhum caminho de troca no modo arma.
- Nota de spec: o GDD (F2) fixa o foco inicial na do meio, e a UX spec (In Review) pede o foco na `ultima_arma`. A story implementa o GDD como padrão e aceita um foco inicial injetado pela composição da run (ADR-0012 `ModeloDeFoco.definir_alvos(n, inicial, …)`), para que a UX valha quando a composição informar `ultima_arma`. **Divergência registrada para o ux-designer/game-designer.**
- Chaves `MENU_*`/`ARMA_*`; aviso da Besta é chave do ux-designer.

---

## Out of Scope

- Story 008: Escolha do Pacto (aberta ao confirmar a Besta com ≥ 2 pactuadas)
- Épico `armas-das-doutrinas`: montagem dos `DadosDaCarta` de arma

---

## Files

- `src/presentation/ui/tela_escolha_de_arma.gd`, `scenes/ui/escolha_de_arma.tscn`, `porta_da_escolha_de_arma.gd` (novos)
- `tests/unit/tela_bencao/modo_arma_test.gd`
- `production/qa/evidence/escolha-de-arma-3-cartas.png`, `escolha-de-arma-aviso-besta.png`

Código atual: a seleção de arma da fatia (se houver em `main.gd`) é substituída.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshots AC-TB-38 em `production/qa/evidence/`; `tests/unit/tela_bencao/modo_arma_test.gd`
**Status**: [x] Complete (`tests/unit/tela_bencao/modos_arma_maldicao_e_consentimento_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-005-carta-view-e-vista-da-tela.md`; `production/epics/armas-das-doutrinas/` (dados das cartas de arma); `production/epics/run-e-regioes/` (composição, `PortaDaEscolhaDeArma`)
- Unlocks: `production/epics/tela-de-bencao-e-carta/story-008-modo-maldicao-escolha-do-pacto.md`; `production/epics/hud/story-010-tela-de-fim-de-run.md` ("Nova run")
