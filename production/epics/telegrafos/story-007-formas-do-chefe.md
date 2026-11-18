# Story 007: Formas do chefe (setor, avanço, anel, círculo e contorno secundário)

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R5a)
**Requirement**: `TR-telegrafos-005`, `TR-telegrafos-015` (padrões do chefe)

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisões 9–12)
**ADR Decision Summary**: Padrões do chefe vêm do `BossPatternDef` pelo mesmo `FormaDeTelegrafo`/`derivar`; `ANEL` e `CIRCULO` entram no MVP. Contorno tracejado do puxão (420 px) é o 2º contorno do mesmo telégrafo, fora do teto (`contorno_secundario_raio`). Chefe tem 1 telégrafo por vez; pior caso 1 + 3 lacaios = 4.
**ADR Version**: ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: mesma montagem para teste e vista
- Forbidden: conta de forma fora do adaptador
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TG-36 — P0 `setor` 165 px, 78,46°, preparo 30; P1 `retangulo` 414 × 144 desde −72, 36; P2 `anel` 0–210 `borda_ao_centro`, 36; P3 `circulo` 225, 42, contorno tracejado 420; lista do chefe ≤ 1 ativo
- [x] AC-TG-37 — só o alvo travado: P2 no jogador → `ferir_jogador(15)` uma vez, `ferir_maldicao` nunca (anel e 12 projéteis); P0 → só jogador (16); P1 → só jogador uma vez (18); P3 travado na Maldição → os dois puxados 75 px, só a Maldição recebe 14
- [x] AC-TG-39 (parte) — `derivar` dos `BossPatternDef` de fábrica sem TV3–TV5 (a validação em si: story-009)

---

## Implementation Notes

- O contrato do traço secundário é **[a confirmar]** no GDD (R5a): implementar o campo `contorno_secundario_raio` e deixar o desenho para o Pipeline.
- Puxão e pulso não são golpes (Chefes R3): o teste usa dublê de `DeslocamentosDoChefe`.

---

## Out of Scope

- Máquina de luta do chefe: épico IA story-009 e épico chefes

---

## Files

- src/gameplay/telegrafos/formas_de_telegrafo.gd
- src/gameplay/telegrafos/forma_de_telegrafo.gd
- tests/unit/telegrafos/telegrafos_formas_do_chefe_test.gd

Fatia: sem chefe na fatia.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_formas_do_chefe_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-005-alvo-travado.md`; épico `production/epics/chefes/` (`BossPatternDef` no catálogo; dublê basta)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-009-chefe-ativo-e-lacaios.md`
