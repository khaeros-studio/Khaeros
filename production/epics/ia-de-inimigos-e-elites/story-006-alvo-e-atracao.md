# Story 006: Alvo efetivo, atração sem renovação e respiro

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R16, R17, F6)
**Requirement**: `TR-ia-015` (alvo exposto e atrair)

**ADR Governing Implementation**: ADR-0018 (§3 passo 3, §4, §5); ADR-0017: Aliados e invocações; ADR-0010
**ADR Decision Summary**: `alvo_efetivo(id)` puro, prioridade Maldição atraída > acuada por paridade > jogador, em `AlvoDeInimigo` pré-alocado. `passo()` lê o alvo **antes** de descer `restante_atracao`/`restante_respiro`; o fim da atração abre o respiro no mesmo passo. `atrair(id, passos, respiro)` aceita só se atingível, Maldição em campo e atração e respiro em 0 (sem renovação). `maldicao_saiu_de_campo(player_id)` zera atração, abre respiro e incrementa `epoca_campo`; alvo travado ausente = falha no vazio.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0017 2026-11-16 · ADR-0010 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: golpe testa só o alvo travado; falha no vazio, nunca redireciona
- Forbidden: expor `InimigoRef`
- Guardrail: `alvo_efetivo` sem alocação

---

## Acceptance Criteria

- [x] AC-IA-31 — `atrair(eco, 90, 30)` em `s`: anda para a Maldição de `s` a `s+89`; respiro `s+90`–`s+119` para o jogador; `esta_atraido` falso
- [x] AC-IA-32 — alcance pelo alvo: Vulto 75 entra / 76 não; Maldição de 30 px: 81 / 82
- [x] AC-IA-33 — Maldição sai em `s`: atração 0, respiro 30, alvo jogador; novo `atrair` recusado até `s+29`, aceito em `s+30`
- [x] AC-IA-34 — travado na Maldição que sai no passo 10: nenhum `ferir_*`, parado 10, recuperação
- [x] AC-IA-35 — atração no passo 5 do preparo: disparo testa o jogador; recuperação anda para a Maldição
- [x] AC-IA-36 — sem renovação: aceita com 0; recusa com 40; respiro recusa; elite aceita; surgindo/Vida ≤ 0/sem Maldição: recusa
- [x] AC-IA-43 — Anomalia atraída recua da Maldição a 1,95; Fenda atraída parada a 400, prepara a 570
- [x] AC-IA-44 — `fator_andar_atraido` 0,80: 2,04 px/passo; no Selo 1,02; avanço 7,56
- [x] AC-IA-47 — sem Maldição em campo: `atrair`/`imobilizar` nunca chamados; AC-IA-01..30 passam sem mudança

---

## Implementation Notes

- Porta `ConsultaDaMaldicao` (ADR-0017: `maldicao_em_campo`, `posicao_e_raio`, `maldicao_atingivel`, `fator_andar_atraido`) com dublê; ADR-0017 e 0018 dependem só por interface.

---

## Out of Scope

- story-007: imobilizar/puxar; story-008: acuada

---

## Files

- src/gameplay/ia/alvo_de_inimigo.gd
- src/gameplay/ia/modulo_de_ia.gd
- tests/unit/ia/ia_alvo_e_atracao_test.gd

Fatia: sem Maldições; nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_alvo_e_atracao_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-003-ranged-charger-e-vista.md`; `production/epics/telegrafos/story-005-alvo-travado.md`
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-007-imobilizar-puxar-e-conter.md`, `story-008-acuada-por-paridade.md`; stories de técnicas em `production/epics/maldicoes/`
