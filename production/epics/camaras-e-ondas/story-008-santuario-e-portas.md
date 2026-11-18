# Story 008: Santuário e portas físicas (posição, alcance, interação)

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R12, R13, R11-P, R13-P)
**Requirement**: `TR-camaras-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4.3–4.4); ADR-0006: Input por passo; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Portas têm estado, posição e alcance de 111 px; Interagir é lido da amostra do passo e só vale em passo vivo (ignorado em hitstop e Transição, bloqueado em Aguardando pacto); a escolha emite `porta_escolhida(k)` e as Câmaras pedem `TRANSICAO`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0001/ADR-0006)
**Engine Notes**: Input pela amostra própria do passo (ADR-0006), nunca `Input.is_action_*` direto na lógica.

**Control Manifest Rules (Feature)**:
- Required: troca de estado só por `pedir_estado`
- Forbidden: ler `Input` da engine na lógica

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-17: santuário com Vida 70/100 cura 30; 40/100 cura 40; fase Limpa, portas abrem, sem ondas; pedra de raio 63 px em (960; 495).
- [x] AC-CO-18 / AC-CO-40: portas nascem fechadas; 2 portas em x = 735/1185, 3 em 510/960/1410, y = 177; forçada única em x = 960; depois do índice 4, 2 ou 3 livres; depois do 5, 1 porta `chefe`; depois do 6, nenhuma; `ultima` não aparece.
- [x] AC-CO-19 / AC-CO-20: Interagir a 111 px escolhe, a 112 px nada; nunca duas ao alcance; em hitstop ou Transição nada; a interação pede a Transição e a próxima câmara é montada na metade do wipe.
- [x] AC-CO-39: câmara do encontro limpa com a acuada em `Aguardando` → fase Limpa, "em combate" falso, portas fechadas até as Portas pedirem a abertura (após `pacto_resolvido`).

---

## Implementation Notes

- A recompensa e a contagem de portas são das Portas (ADR-0015 §4.3); as Câmaras só posicionam, abrem e detectam a interação.
- A cura do santuário lê `vida_max` do `Portador` (ADR-0009).

---

## Out of Scope

- Épico portas-e-recompensas: quantas portas e com que recompensa
- Story 010: aparência das portas

---

## Files

- `src/gameplay/camaras/portas_fisicas.gd`
- `tests/unit/camaras/santuario_e_portas_test.gd`

Código atual da fatia: a fatia não tem portas; `game_input.gd` é **adaptado** pelo épico input para expor Interagir na amostra do passo.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/santuario_e_portas_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-007-ciclo-de-combate-e-limpar.md`; `production/epics/input/EPIC.md` (Interagir por passo) e `production/epics/portas-e-recompensas/EPIC.md` (stories a criar)
- Unlocks: `production/epics/camaras-e-ondas/story-010-evidencia-visual-arena-e-portas.md`
