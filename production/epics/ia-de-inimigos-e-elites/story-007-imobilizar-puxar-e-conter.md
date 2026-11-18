# Story 007: Imobilizar, puxar (Convergência) e Maldição fora da separação

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R18, R20; TR-ia-019 da emenda Pactos)
**Requirement**: `TR-ia-015` (imobilizar só em comuns), `TR-ia-019`

**ADR Governing Implementation**: ADR-0018 (§3, §5, §6); ADR-0017: Aliados e invocações; ADR-0008
**ADR Decision Summary**: `imobilizar(id, passos)`: só comum atingível (inclusive lacaio), `restante_imob = max(...)`; elite e chefe devolvem falso. Imobilizado não anda nem começa preparo; `timer` desce; preparo/execução em curso continuam; empurrão e separação ainda movem. `puxar(id, centro, distancia_px, parar_a_px)`: só comuns e elites atingíveis, chefe falso; desloca `min(distancia_px, max(0, d − parar_a_px))` rumo ao centro e aplica `resolver_colisao`; síncrono no 6.1; não é golpe. `conter(pos, raio)` exposto para o corpo da Maldição.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0017 2026-11-16 · ADR-0008 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: separação nunca inclui Maldição/acuada
- Forbidden: `puxar` mudar fase ou alvo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-IA-37 — `imobilizar(eco, 90)` em `s`: parado `s`–`s+89`, sem preparo, `timer` desce; em `s+90` `iniciar_telegrafo` 1×
- [x] AC-IA-38 — preparo em curso dispara no 26; avanço em curso completa 26 a 7,56; recuperação seguinte não anda
- [x] AC-IA-39 — `imobilizar` em elite/chefe: falso, `esta_imobilizado` falso; `atrair` neles: verdadeiro
- [x] AC-IA-40 — empurrão 360 px/s move o imobilizado; dois imobilizados a 20 px se separam 14 cada
- [x] AC-IA-42 — Maldição sobreposta 20 px a um Eco: ninguém é empurrado pela separação; Maldição dentro de obstáculo: `conter` a devolve
- [x] TR-ia-019 (sem AC numerado no GDD; critério do ADR-0018 §5) — `puxar` aceita comum e elite, chefe recusa; deslocamento `min(distancia_px, max(0, d − parar_a_px))`, depois `resolver_colisao`; o item 7 do mesmo passo parte da posição nova

---

## Implementation Notes

- A mesma conta de `puxar` serve ao puxão do chefe (`FormulasDoChefe.passo_puxao`, F3) — colocar a função pura num lugar só.
- **Decisão registrada:** TR-ia-019 não tem AC-IA próprio no GDD; o critério vem do ADR-0018 §5 (texto do ADR, não inventado). Sinalizar ao game-designer para numerar um AC.

---

## Out of Scope

- A técnica Convergência em si (épico maldicoes)

---

## Files

- src/gameplay/ia/modulo_de_ia.gd
- src/gameplay/ia/formulas_do_chefe.gd
- tests/unit/ia/ia_imobilizar_puxar_test.gd

Fatia: sem equivalente.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_imobilizar_puxar_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-004-andar-conter-e-separacao.md`, `production/epics/ia-de-inimigos-e-elites/story-006-alvo-e-atracao.md`
- Unlocks: stories de técnicas em `production/epics/maldicoes/`
