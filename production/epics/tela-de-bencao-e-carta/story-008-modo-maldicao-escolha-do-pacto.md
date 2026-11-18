# Story 008: Modo maldicao — Escolha do Pacto com duas escolhas em ordem

> **Epic**: Tela de bênção e carta (reusa `CartaView` + `GrupoDeCartas`; spec `design/ux/tela-escolha-de-arma-e-pacto.md`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R15b-P); `design/gdd/vinculo-e-pactos.md` V16, V16b; `design/gdd/maldicoes.md` R2; UX: `design/ux/tela-escolha-de-arma-e-pacto.md`
**Requirement**: `TR-tela-bencao-015` (TR-vinculo-003 fica no épico `vinculo-e-pactos`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisão 10, "Tela Escolha do Pacto"); ADR-0006: Input por passo
**ADR Decision Summary**: `Control` no estado de menus/escolha de arma com `ModeloDeFoco` e `ComandosDeTela`; lista as espécies pactuadas por `LeituraDoPerfil` (a UI nunca lê `perfil.cfg`); devolve a dupla por `PortaDaEscolhaDeDupla.confirmar(campo, reserva)`. Modo `maldicao` do `GrupoDeCartas`: duas escolhas em ordem (campo, depois reserva), sem troca; `ultima_dupla` pré-selecionada; `aviso_texto` opcional.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0006 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: n ≤ 4 usa a largura reservada de 4 cartas (R3) e seleção direta 1–3 (R13).

**Control Manifest Rules (Presentation)**:
- Required: UI recebe entrada só por `ComandosDeTela`; `CartaView` recebe `DadosDaCarta`
- Forbidden: a UI ler `perfil.cfg`
- Guardrail: UI ≤ 80 draw calls

---

## Acceptance Criteria

*From `design/ux/tela-escolha-de-arma-e-pacto.md` §14 (spec In Review) e GDD R15b-P:*

- [x] Confirmar a Besta com 3 pactuadas abre a Escolha do Pacto; com 1, vai direto à carga com aviso curto e `dupla_confirmada(id, "")`.
- [x] A mesma espécie não pode ocupar os dois slots; Esc desfaz Reserva, depois Campo, depois volta à arma sem seed criada.
- [x] Com `ultima_dupla` válida, os dois slots chegam preenchidos e um Confirmar inicia a run.
- [x] Trava R7, entrada R10 e acessibilidade R14 valem como na Tela de bênção (topo neutro; raridade da espécie por palavra e ornamento).
- [x] Concluída só com gamepad e só com teclado; foco com anel + escala visível em tons de cinza.

---

## Implementation Notes

*Derived from ADR-0012 §10:*

- `abrir(cartas, 0, t, &"maldicao")`; sub-estado "escolhendo campo / escolhendo reserva" dentro do modo; `voltar` desfaz em ordem.
- O corpo da carta (nível, barra de vínculo, kit, memórias) vem pronto em `DadosDaCarta` montados pelo Vínculo.

---

## Out of Scope

- Story 009: tela de consentimento (dentro da run)
- Épico `vinculo-e-pactos`: `LeituraDoPerfil`, `dupla_confirmada`, criação da seed

---

## Files

- `src/presentation/ui/tela_escolha_do_pacto.gd`, `scenes/ui/escolha_do_pacto.tscn`, `porta_da_escolha_de_dupla.gd` (novos); `grupo_de_cartas.gd` (modo `maldicao`)
- `tests/unit/tela_bencao/modo_maldicao_test.gd`
- `production/qa/evidence/escolha-do-pacto-campo-reserva.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshot em `production/qa/evidence/`; `tests/unit/tela_bencao/modo_maldicao_test.gd`
**Status**: [x] Complete (`tests/unit/tela_bencao/modos_arma_maldicao_e_consentimento_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-007-modo-arma-escolha-de-arma.md`; `production/epics/vinculo-e-pactos/` (`LeituraDoPerfil`, `PortaDaEscolhaDeDupla`); `production/epics/assets-e-conteudo/story-007-arte-de-maldicoes-e-chefe.md` (retratos/silhuetas das espécies)
- Unlocks: None
