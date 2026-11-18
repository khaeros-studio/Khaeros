# Story 008: Alvo padrão acuada por paridade (encontro de pacto)

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R22, F6)
**Requirement**: `TR-ia-018`

**ADR Governing Implementation**: ADR-0018 (§4); ADR-0017 (§11)
**ADR Decision Summary**: `alvo_padrao` fixado no nascimento: `ACUADA` se a câmara tem acuada em `Acuada` e `ordem ≥ 0` par; senão `JOGADOR`; lacaios `ordem = −1`. `alvo_efetivo` relê `acuada_atingivel()` (porta `ConsultaDaAcuada` do Vínculo) a cada leitura, então a fuga vale no mesmo item 7 para quem ainda não agiu; vale também no respiro; suspenso enquanto atraído. Golpe na acuada só por `ferir_acuada`.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0017 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: só o alvo travado é testado
- Forbidden: acuada na separação ou em `atingiveis()`
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-IA-50 — ordens 0 e 2 miram a acuada, 1 o jogador; sem acuada todos o jogador; lacaio −1 o jogador
- [x] AC-IA-51 — ordem 0 com os dois no setor: `ferir_acuada(9, M)` 1×; ordem 1: só `ferir_jogador`
- [x] AC-IA-52 — alcance pela acuada: 73,5 entra, 74 não
- [x] AC-IA-53 — Eco 0 derruba a acuada em `s`: Eco 2 lê o jogador no mesmo passo; de `s+1` todos o jogador; idem `Aguardando`
- [x] AC-IA-54 — travado na acuada que foge: nenhum `ferir_*`, segue para recuperação
- [x] AC-IA-55 — ordem 0 atraído: Maldição `s`–`s+89`, respiro para a acuada (ou jogador se `Fugiu`); ordem 1: respiro para o jogador
- [x] AC-IA-56 (parte R22) — Eco sobreposto 20 px à acuada: separação não move nenhum
- [x] AC-IA-57 — Anomalia ordem 0 recua da acuada a 1,95; `disparar_projetil` com `alvo = acuada`

---

## Implementation Notes

- `ordem` vem de `OpcoesDeNascimento` (Câmaras); a IA não valida posição de nascimento.

---

## Out of Scope

- Estado da acuada (épico vinculo-e-pactos)

---

## Files

- src/gameplay/ia/modulo_de_ia.gd
- src/gameplay/ia/consulta_da_acuada.gd
- tests/unit/ia/ia_acuada_test.gd

Fatia: sem equivalente.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_acuada_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-006-alvo-e-atracao.md`; épico `production/epics/combate-nucleo/` (`ferir_acuada`); épico `production/epics/vinculo-e-pactos/` (porta; dublê basta)
- Unlocks: stories do encontro em `production/epics/vinculo-e-pactos/`
