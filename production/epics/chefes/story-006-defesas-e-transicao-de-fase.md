# Story 006: Defesas do chefe e TransicaoFase (armadura, imobilização, invulnerabilidade)

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R1, R7; F4; Edge Cases)
**Requirement**: `TR-chefes-010`, `TR-chefes-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0018 (§8 TransicaoFase); ADR-0010: Resolução do combate no passo; ADR-0009: Atributos e modificadores
**ADR Decision Summary**: logo após aplicar dano a um `chefe`, o Combate chama `ia.notificar_dano_no_chefe(id)`; se `¬em_furia` e `0 < Vida ≤ round(vida_max × limiar_furia_frac)`, fora de `EXECUCAO` entra em `TRANSICAO_FASE` na hora (cancela o telégrafo, pulso pendente), em `EXECUCAO` marca `transicao_pendente`. `invulneravel_por_fase(id)` (dano × 0, empurrão 0) vale desde o golpe que cruzou o limiar. Armadura total, imunidade a imobilização, fonte chefe (empurrão × 0,12), Abalo funciona.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: risco herdado do ADR-0010; arredondamento determinístico próprio do ADR-0009 (sem `round()` da engine para regra).

**Control Manifest Rules (this layer)**:
- Required: mudanças de Vida só pela interface do Combate (ADR-0003)
- Forbidden: TransicaoFase checada só no passo da IA (alternativa rejeitada no ADR-0018)

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-02** Em `Preparo` do P0 (`restante = 15`), 3º Corte pesado (25,2, empurrão 900): 25,2 de dano, empurrão 108 px/s, sem cambalear, sem "Quebrou!", telégrafo vai a 14.
- [x] **AC-CH-03** Chamado do Pacto + Abalo: não imobiliza; `atraído` 90 passos (emenda: `duracao_atracao_s` 1,5) e Abalo ativo (dano causado × 0,70); um 2º Chamado nos 30 passos seguintes é recusado.
- [x] **AC-CH-12** Fase 1, `Preparo` do P2, Vida 360, jogador a 130 px, sofre 25 (335 ≤ 350): o telégrafo é cancelado sem disparar, `TransicaoFase` 30 passos vivos, jogador empurrado 120 px para 250 px sem dano, golpes no chefe nesses 30 passos causam 0.
- [x] **AC-CH-14** Vida 355, golpe único de 400: não entra em `TransicaoFase`, vai direto a `HitstopFinal`.

---

## Implementation Notes

*Derived from ADR-0018 §8:*

- `padrao` avança na saída só se a transição interrompeu `PREPARO` ou veio depois de `EXECUCAO`. Se a transição entrou no item 8, a contagem começa no item 7 seguinte.
- Teste extra (ADR-0018 Validation): 351 → 340 no item 5 já invulnerável no item 6.1; transição no meio do avanço do P1 entra no passo seguinte ao fim.

---

## Out of Scope

- Story 010: leitura visual da Fase 2.

---

## Files

- `src/gameplay/ia/comportamento_chefe.gd`
- `src/gameplay/combate/` (chamada `notificar_dano_no_chefe`, leitura de `invulneravel_por_fase`)
- `tests/unit/chefes/chefes_transicao_e_defesas_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chefes/chefes_transicao_e_defesas_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-003-padroes-0-e-1-e-alvo-travado.md`; épicos `production/epics/combate-nucleo/EPIC.md`, `production/epics/efeitos-de-status/EPIC.md` (Abalo), `production/epics/maldicoes/EPIC.md` (Chamado; dublê aceitável)
- Unlocks: `production/epics/chefes/story-008-queda-do-chefe-e-limpeza.md`

**Código da fatia**: nenhum equivalente; construção do zero.
