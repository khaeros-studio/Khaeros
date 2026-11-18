# Story 009: Cinco bênçãos por run e bênçãos com a Besta do Vínculo

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R13-P, R14-P, Edge Cases Pactos)
**Requirement**: `TR-bencaos-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Atributos e modificadores
**ADR Decision Summary**: Bênção de `dano_todo_pct` (e `velocidade_pct`) espelha em cada portador da dupla no mesmo passo, inclusive a Exausta; Tradição de slot (`dano_ataque_pct`) fica só no jogador (no Virote).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Nenhuma API de engine.

**Control Manifest Rules (Feature)**:
- Forbidden: a Bênçãos tratar a Maldição de forma especial (a propagação é do Modificadores)

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-24: 5 pedidos com chaves 0, 1, 2, 4 e 5, pegando sempre a carta 0 → a 5ª oferta tem 3 cartas distintas, nenhuma tomada; depois, `restantes()` = 13, `tomadas()` com 5 entradas, nenhum `sem_bencao`.
- [x] AC-BN-26: Besta com 1 Maldição em campo; Traço Único Comum sobe o M do Virote e não muda o `dano_todo` da Maldição; bênção de `dano_todo_pct` dá o espelho ao portador da Maldição no mesmo passo (dublê do Modificadores).

---

## Implementation Notes

- `tipos_propagados_maldicao` está **[a confirmar]** no Modificadores (OQ 7); o teste usa a hipótese do GDD e falha visivelmente se o dado mudar.

---

## Out of Scope

- Épico modificadores: implementação do espelho
- Épico maldicoes: portador da Maldição

---

## Files

- `tests/integration/bencaos/cinco_bencaos_e_besta_test.gd`

Código atual da fatia: nenhum (a fatia não tem Besta nem Maldição).

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

- Depends on: `production/epics/bencaos-tradicoes/story-006-escolha-aplicar-e-eventos.md`; `production/epics/modificadores/EPIC.md` e `production/epics/maldicoes/EPIC.md` (stories a criar; AC-BN-24 roda antes com dublês)
- Unlocks: None
