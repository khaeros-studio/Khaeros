# Story 009: Chefe ativo na máquina de fases — TransicaoFase, Subjugado e lacaios

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R21); `design/gdd/chefes.md` (R1–R8, referência)
**Requirement**: `TR-ia-017`

**ADR Governing Implementation**: ADR-0018 (§8); ADR-0010 (`subjugar`, `invulneravel_por_fase`, `notificar_dano_no_chefe`); ADR-0014 (`cancelar`)
**ADR Decision Summary**: `ComportamentoChefe` usa a mesma máquina com `EstadoDoChefe` no `InimigoRef`; sem RNG (esperas fixas). `notificar_dano_no_chefe` dispara `TRANSICAO_FASE` (cancelar telégrafo, `invulneravel_por_fase`, fim de atração com respiro); `subjugar` deixa o chefe na lista, fora de `atingiveis()` e da separação, sem colisão ofensiva. Lacaios `invocado_pelo_chefe`, `ordem −1`, criados no fim do `passo()` do chefe, rodam `melee` e consomem `ia`, nunca `elites` nem `spawn`.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0010 2026-11-16 · ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: chefe nunca consome RNG
- Forbidden: lacaios consumirem `elites`/`spawn`
- Guardrail: ≤ 9 inimigos simultâneos com chefe e lacaios

---

## Acceptance Criteria

- [x] AC-IA-45 — `comportamento = chefe` carrega sem IV4; nunca elite; Vida 700 sem `depth_hp_bonus`; montar a câmara até o 1º padrão não consome `ia` nem `elites`
- [x] AC-IA-46 — `eco_perdido` lacaio segue R3–R9, aceita `imobilizar` e `atrair`, não consome `elites` nem `spawn`
- [x] AC-IA-48 — chefe trava P2 no jogador: `ferir_jogador(15)` 1× pelo anel, `ferir_maldicao` nunca (nem pelos 12 projéteis); atraído no Preparo: o inverso
- [x] AC-IA-49 — atraído com 50 entra em `TransicaoFase` em `s`: atração 0, respiro 30; `atrair` em `s+10` falso, em `s+30` verdadeiro

---

## Implementation Notes

- Escopo: a máquina de luta (ADR-0018 §8). O desfecho (`ModuloDeChefes`: `chefe_vencido`, `resolver_subjugado`, crédito) e o conteúdo dos 4 padrões são do épico `production/epics/chefes/` — coordenar para não duplicar.

---

## Out of Scope

- Desfecho e escolha pactuar/exorcizar (épico chefes); formas dos padrões (`production/epics/telegrafos/story-007-formas-do-chefe.md`)

---

## Files

- src/gameplay/ia/comportamento_chefe.gd
- src/gameplay/ia/estado_do_chefe.gd
- tests/unit/ia/ia_chefe_ativo_test.gd

Fatia: sem chefe.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_chefe_ativo_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-006-alvo-e-atracao.md`; `production/epics/telegrafos/story-006-quebrar-e-cancelar.md`, `production/epics/telegrafos/story-007-formas-do-chefe.md`
- Unlocks: stories do chefe do Limiar em `production/epics/chefes/`
