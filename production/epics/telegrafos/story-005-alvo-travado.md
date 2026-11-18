# Story 005: Alvo travado e falha no vazio (emenda Pactos)

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R2a, R2b, R6a, F7)
**Requirement**: `TR-telegrafos-015`, `TR-telegrafos-016`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisões 9, 10, 12)
**ADR Decision Summary**: `iniciar_telegrafo(id, ataque, alvo_id, alvo_faccao)` guarda alvo, facção e raio do alvo; mira = direção ao alvo; nada disso muda até liberar. `dentro` testa só o alvo travado; `alvo_de(id)` diz qual `ferir_*` chamar. Alvo que sai de campo = falha no vazio. Maldição nunca cria telégrafo; teto segue 24.
**ADR Version**: ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: golpe testa só o alvo travado
- Forbidden: percorrer "todos os jogadores"; expor `TelegrafoSlot`/`InimigoRef`
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TG-28 — Eco atraído: mira (0;1); sem atração (1;0); atração acaba no passo 10: mira, alvo e raio iguais
- [x] AC-TG-30 — travado na Maldição com os dois dentro: só `ferir_maldicao(9)`; travado no jogador: só `ferir_jogador(9)`
- [x] AC-TG-31 — Maldição sai no passo 20 (ou Vida ≤ 0): `disparo` com flash, nenhum `ferir_*`
- [x] AC-TG-32 — projétil travado na Maldição atravessa o jogador; fere a Maldição uma vez; ela sai: some na parede
- [x] AC-TG-33 — avanço travado no Baluarte: 59 px fere, 61 não; jogador a 30 px não é ferido
- [x] AC-TG-34 — Troca põe a Maldição B no setor: nenhuma é ferida
- [x] AC-TG-35 — Maldição faz 3 básicos e um Chamado: lista não muda; teto 24

---

## Implementation Notes

- `ConsultaDeAlvoMaldicao` é porta definida aqui (ADR-0014), implementada pelo épico maldicoes; testes com dublê.
- A validação de época/saída de campo é da IA (ADR-0018 §4); Telégrafos só guarda e testa.

---

## Out of Scope

- Escolha do alvo (`alvo_efetivo`): épico IA story-006/008

---

## Files

- src/gameplay/telegrafos/telegrafos.gd
- src/gameplay/telegrafos/consulta_de_alvo_maldicao.gd
- tests/unit/telegrafos/telegrafos_alvo_travado_test.gd

Fatia: sem Maldições na fatia; nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_alvo_travado_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-004-disparo.md`; épico `production/epics/combate-nucleo/` (`ferir_maldicao`, `disparar_projetil` com `alvo_id`)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-006-alvo-e-atracao.md`
