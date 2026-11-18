# Story 003: Troca, confirmação, PortaDaBencao e sinais preco_revelado / tela_fechada

> **Epic**: Tela de bênção e carta
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R8, R9, Edge Cases)
**Requirement**: `TR-tela-bencao-006`, `TR-tela-bencao-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisões 5, 11); ADR-0002: Canal de eventos
**ADR Decision Summary**: A Tela responde por `PortaDaBencao` (`@abstract`, injetada): `escolher(i)` no passo do aperto, `trocar()`, `notificar_tela_fechada()`. Ao processar os comandos de um passo, `trocar` é testado **antes** de `aceitar`: com cargas só troca; sem cargas a troca não existe e o aceitar vale. Dois aceitar no mesmo passo: vale o do foco. A `VistaDaTela` emite os sinais Godot `preco_revelado` e `tela_fechada`, ligados pelo `Main` ao HUD e ao Feedback/Áudio.
**ADR Version**: ADR-0012 2026-11-16 · ADR-0002 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `@abstract` com retorno tipado não-void exige `return` (4.7); dublês de teste estendem as bases.

**Control Manifest Rules (Presentation)**:
- Required: sinais do Godot só em nós de Apresentação, conectados pelo `Main`
- Forbidden: a Tela referenciada pelo módulo de regra (oferta chega por `OfertaAberta`/`OfertaTrocada` na lista)
- Guardrail: `escolher` no quadro do aperto

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md`:*

- [x] AC-TB-13 [L] R8 — trocas 1: `trocar()` uma vez, cartas e cargas atualizadas (0), foco volta a F2.
- [x] AC-TB-14 [L] R8 — trocas 0: botão desabilitado (riscado, "0"); R, Y e clique não chamam `trocar()`; treme 80 ms; Confirmar no botão só treme.
- [x] AC-TB-15 [L] R8 — com cargas, troca e confirmar no mesmo quadro: só `trocar()`; sem cargas: `escolher` vale.
- [x] AC-TB-16 [L] R9 — `escolher(i)` uma vez no quadro do aperto; segundo confirmar no quadro ou na animação não chama de novo.
- [x] AC-TB-17 [L] R9 — com preço, o selo racha depois do ganho e `preco_revelado` sai aí; sem preço sai no fim do ganho; animação ≤ 0,6 s; confirmar antes de `preco_revelado` ignorado, depois pula.
- [x] AC-TB-31 [L] R7 — dois confirmar no mesmo quadro: `escolher` uma vez.
- [x] AC-TB-29 [L] R9 — com O Preço com Nome (Vida −10): número de Vida do HUD muda no quadro de `escolher`; rachar só em `preco_revelado`.
- [x] AC-TB-24 [L] R16 — a tela roda com Bênçãos e relógio falsos, sem cena de jogo.

---

## Implementation Notes

*Derived from ADR-0012 §5, §11:*

- `PortaDaBencao` exatamente como em Key Interfaces; dublê `PortaDaBencaoFalsa` em `tests/`.
- Volta para Jogo acontece em `tela_fechada`, não em `escolher`; botões segurados ignorados até soltar (o clique da carta nunca vira golpe).
- Os sinais são da vista (story 005); aqui o modelo expõe os instantes (`preco_revelado_em`, `fechou_em`) que a vista converte em sinais.

---

## Out of Scope

- Story 006: integração com a Bênçãos real (AC-TB-25)
- `production/epics/hud/story-002-vida-segmentos-racha-e-vida-baixa.md`: a espera do rachar no HUD

---

## Files

- `src/presentation/ui/porta_da_bencao.gd` (novo); `grupo_de_cartas.gd` (completar)
- `tests/unit/tela_bencao/troca_e_confirmacao_test.gd`
- `tests/unit/tela_bencao/preco_revelado_hud_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tela_bencao/troca_e_confirmacao_test.gd`, `preco_revelado_hud_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/tela_bencao/grupo_de_cartas_travas_troca_e_sinais_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-002-grupo-de-cartas-estados-e-travas.md`; `production/epics/hud/story-002-vida-segmentos-racha-e-vida-baixa.md` (para AC-TB-29)
- Unlocks: `production/epics/tela-de-bencao-e-carta/story-005-carta-view-e-vista-da-tela.md`, `story-006-integracao-com-bencaos-real.md`
