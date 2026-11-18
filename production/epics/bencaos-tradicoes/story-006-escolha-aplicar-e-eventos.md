# Story 006: Escolha — aplicar no Modificadores, registrar e emitir

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R5, R6, Edge Cases "Escolha e troca")
**Requirement**: `TR-bencaos-004`, `TR-bencaos-005`, `TR-bencaos-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Atributos e modificadores; ADR-0002: Canal de eventos; ADR-0012: UI e HUD (Decisão 11)
**ADR Decision Summary**: O Modificadores aplica `valor × escala[raridade]` no `Portador` (cache reconstruído, arredondamento meio longe de zero) antes do registro; `EvOfertaAberta`/`EvOfertaTrocada`/`EvBencaoTomada` vão pelo canal, e `bencao_tomada` sai em `notificar_tela_fechada()`; a Tela testa `trocar` antes de `aceitar`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0002/ADR-0012)
**Engine Notes**: Nenhuma API pós-cutoff na lógica.

**Control Manifest Rules (Feature)**:
- Required: Apresentação lê a lista de eventos; lógica sem referência à UI
- Forbidden: `round()` sobre valores do Modificadores

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-08: pegar O Muro de Pedras Épico entrega `(Vida máxima 25, Épica)`; Vida base 100 → 150; Rara → 138.
- [x] AC-BN-09: ordem: efeitos aplicados, registro, `bencao_tomada`, `bencao_escolhida`, e só então as Portas abrem as portas.
- [x] AC-BN-10: pular é ignorado; índice 3 numa oferta de 3 cartas é ignorado; troca e escolha no mesmo passo → a troca vence.

---

## Implementation Notes

*Derived from ADR-0009, ADR-0002 e ADR-0012:*

- Payload `EvBencaoTomada`: `player_id`, `id`, `raridade`, `trocas_restantes` (ADR-0002 tabela de eventos).
- A precedência troca × aceitar é implementada no `GrupoDeCartas` da Tela (épico tela-de-bencao-e-carta); aqui o teste usa dublê de Tela que envia os dois comandos no mesmo passo e confirma que a Bênçãos recebe só `trocar`.

---

## Out of Scope

- Épico tela-de-bencao-e-carta: UI das cartas
- Story 009: espelho na Maldição

---

## Files

- `src/gameplay/bencaos/bencaos.gd`
- `tests/integration/bencaos/escolha_aplicar_e_eventos_test.gd`

Código atual da fatia: `game_session.gd::choose_blessing(index)` é **substituído** (aplicava bônus direto nos campos do jogador).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/bencaos/escolha_mundo_e_besta_test.gd`
**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-004-troca-e-raridade-bonus.md`, `production/epics/bencaos-tradicoes/story-005-contrato-pedir-oferta.md`; `production/epics/modificadores/EPIC.md` (`aplicar` com escala — story a criar)
- Unlocks: `production/epics/bencaos-tradicoes/story-008-texto-da-carta.md`, `production/epics/bencaos-tradicoes/story-009-cinco-bencaos-e-besta.md`
