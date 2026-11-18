# Story 004: Conceder a recompensa (Fragmentos, cura, bênção)

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (R1, R3, R4, R5; F1, F1-P, F4)
**Requirement**: `TR-portas-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4, §6, §9); ADR-0009: Atributos e modificadores
**ADR Decision Summary**: Fragmentos vão para `conta.creditar(PORTA, n)` da `ContaFragmentos` injetada (escopo de sessão); a cura lê `vida_max` do `Portador` do jogador; colaboradores ausentes são variantes Nulas com `return` explícito.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: regra 4.7 — todo override com retorno tipado (dublês Nulos) exige `return` explícito. Arredondamento próprio do ADR-0009 (sem `round()`).

**Control Manifest Rules (this layer)**:
- Required: todo colaborador opcional tem variante Nula; nenhum `if x != null` na regra (ADR-0015)
- Required: `saldo` de Fragmentos é de sessão; nunca no `perfil.cfg`
- Forbidden: as Portas escreverem a Vida por fora da interface do dono (Combate) — ADR-0003

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-01** A 1ª câmara da run, sem porta anterior, dá `bencao` ao limpar (`primeira_recompensa`).
- [x] **AC-PR-03** Nenhuma bênção resta: a recompensa vira Fragmentos com a quantidade da R4 (p 1: 2).
- [x] **AC-PR-04 / AC-PR-34** Câmaras limpas em p 0, 1, 2, 3, 4: 2, 2, 2, 3, 3; p 6: 4. Escolhendo Fragmentos depois dos índices 0, 1, 3 e 4 do Limiar: 2, 2, 3 e 3 = 10.
- [x] **AC-PR-05** Vida 50/100: 80; Vida 85/100: 100 (ganho 15, evento 30); Ressonância (80 de Vida máxima, Vida 40): 64 (cura 24); Vida cheia: sem efeito e evento nominal.

---

## Implementation Notes

*Derived from ADR-0015 §4 passo (2) / §6 / ADR-0009:*

- `Portas.conceder(tipo, p)`: Fragmentos → `conta.creditar(&"porta", F1(p))`; cura → pede ao Combate curar `F4(vida_max)` lendo `vida_max` do `Portador`; bênção → `bencaos.pedir_oferta(regiao, i)`; resposta `sem_bencao` → converte em Fragmentos (R3).
- Emite o evento `recompensa(tipo, quantidade_nominal)` (o nominal da cura é o valor da F4, não o ganho efetivo).
- Testes com `ContaFragmentosNula`/espiã, `BencaosNula` e `Portador` em memória.

---

## Out of Scope

- Story 005: ordem dos passos da R2 e quando conceder.
- Épico `economia-de-fragmentos`: `ContaFragmentos` em si.

---

## Files

- `src/gameplay/portas/portas.gd`
- `src/gameplay/portas/formulas_de_portas.gd` (F1, F4)
- `tests/unit/portas/portas_conceder_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/portas/portas_conceder_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-001-reward-table-e-validacao.md`; épicos `production/epics/economia-de-fragmentos/EPIC.md` (`ContaFragmentos` + Nula), `production/epics/bencaos-tradicoes/EPIC.md` (`pedir_oferta`), `production/epics/modificadores/EPIC.md` (`Portador`)
- Unlocks: `production/epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md`

**Código da fatia**: `game_session.gd` não tem recompensas por porta (só bênçãos por onda); não reaproveitar — a concessão de bênção da fatia é substituída pelo épico `bencaos-tradicoes`.
