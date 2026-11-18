# Story 006: Integração com a Bênçãos real — oferta pela lista do passo e tela_fechada

> **Epic**: Tela de bênção e carta
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (R9, R16, Interactions with Other Systems)
**Requirement**: `TR-tela-bencao-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD (decisão 5); ADR-0002: Canal de eventos
**ADR Decision Summary**: A oferta chega como os eventos `OfertaAberta`/`OfertaTrocada` da lista do passo; a Tela responde por `PortaDaBencao`. A Bênçãos segura `bencao_escolhida` até `notificar_tela_fechada()` e só então pede `JOGO`. Chamadas à porta durante a entrega do final comum emitem eventos que saem no passo seguinte (Risks).
**ADR Version**: ADR-0012 2026-11-16 · ADR-0002 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: ordem dos consumidores na entrega: Telemetria, HUD, Feedback, Telas, Áudio (emenda ADR-0012/0016).

**Control Manifest Rules (Presentation)**:
- Required: sinais Godot conectados explicitamente pelo `Main`; a Apresentação só lê e nunca escreve no jogo (escreve só pela porta injetada)
- Forbidden: o módulo de regra referenciar um nó
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md`:*

- [x] AC-TB-25 [I] R9 — oferta de 3 cartas: escolher a 2 emite `bencao_tomada` uma vez (no passo N+1 se a chamada ocorreu na entrega do final comum); `bencao_escolhida` só depois de `tela_fechada`, e as portas abrem depois disso; `sem_bencao` não abre a tela.
- [x] Edge — vitória logo depois da escolha: a Run só encerra depois de `tela_fechada`.

---

## Implementation Notes

*Derived from ADR-0012 §5 e Risks:*

- `PortaDaBencaoReal` adapta o módulo Bênçãos; o `Main` conecta `tela_fechada` → `notificar_tela_fechada()`.
- Teste de integração com orquestrador e Bênçãos reais, sem vista (modelo + porta real).

---

## Out of Scope

- Épico `bencaos-tradicoes`: o sorteio, a aplicação do efeito e o segurar de `bencao_escolhida`

---

## Files

- `src/presentation/ui/porta_da_bencao_real.gd` (novo); `src/app/main.gd` (adaptar)
- `tests/integration/tela_bencao/bencaos_real_test.gd`

Código atual: o fluxo de escolha em `main.gd`/`game_session.gd` (carta escolhida aplicada direto) é substituído pela porta.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/tela_bencao/bencaos_real_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/tela_bencao/tuning_carta_view_e_bencaos_real_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/tela-de-bencao-e-carta/story-003-troca-confirmacao-e-sinais.md`; `production/epics/bencaos-tradicoes/` (story da oferta e de `bencao_escolhida`); `production/epics/orquestrador-do-passo/` (estado `BENCAO`)
- Unlocks: None
