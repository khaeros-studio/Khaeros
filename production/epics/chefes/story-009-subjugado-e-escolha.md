# Story 009: Subjugado e escolha Pactuar/Exorcizar (R9b)

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R9, R9b.2–R9b.4; F6 emenda Pactos)
**Requirement**: `TR-chefes-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 (§4 passo 5); ADR-0002; ADR-0010; ADR-0018 (§8)
**ADR Decision Summary**: em Pactos, Combate marca `Subjugado` em `s`; Chefes emitem `EvChefeSubjugado` em `s + 37`; a escolha chega pelo Vínculo (`chefe_escolhido`) e, no 1º passo vivo seguinte, Chefes executam em ordem síncrona `resolver_subjugado(id, escolha)` → `creditar(chefe, 6)` (só Exorcizar) → `limpar_camara_chefe()`; as Câmaras emitem `camara_limpa(4, chefe)` no item 10 desse passo. Escolha repetida é ignorada.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: eventos tipados (`@abstract EventoDoPasso`, 4.5+) com `tipo()` de `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: o módulo de Chefes não emite `camara_limpa` em nenhum caso
- Required: reação a produtor do mesmo item ou posterior por chamada direta (ADR-0002)

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-17** Pactos: após os 36 de hitstop, `Subjugado` e `chefe_subjugado("soberano_do_limiar")`; após `pactuar`, 0 Fragmentos de chefe, pacto registrado (dublê de Vínculo) e `camara_limpa(4, chefe)`.
- [x] **AC-CH-18** `exorcizar` em `Subjugado`: `creditar(chefe, 6)` e `camara_limpa(4, chefe)`.
- [x] **AC-CH-24** Com espiões no Combate, Economia e Câmaras: `exorcizar` → no mesmo passo vivo, em ordem, `resolver_subjugado(id, exorcizar)`, `creditar(chefe, 6)`, `limpar_camara_chefe()`; `camara_limpa` 1 vez, pelas Câmaras. `pactuar`: sem `creditar`. Uma 2ª escolha não gera chamada.

---

## Implementation Notes

*Derived from ADR-0018 §8 / ADR-0015 §4:*

- `ModuloDeChefes.escolha(id, escolha)` guarda a escolha pendente; `passo_vivo()` a executa. A abertura da tela (OQ1 do GDD: automática ou por Interagir) é do Vínculo — fora desta story.

---

## Out of Scope

- Épico `vinculo-e-pactos`: tela Pactuar/Exorcizar e registro do pacto.
- `production/epics/run-e-regioes/story-006-vitoria.md`: vitória e `desfecho_chefe`.

---

## Files

- `src/gameplay/chefes/modulo_de_chefes.gd`
- `src/gameplay/chefes/eventos_de_chefes.gd` (`EvChefeSubjugado`)
- `tests/integration/chefes/chefes_subjugado_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/chefes/chefes_subjugado_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-008-queda-do-chefe-e-limpeza.md`; `production/epics/run-e-regioes/story-006-vitoria.md`; épico `production/epics/vinculo-e-pactos/EPIC.md` (`chefe_escolhido`; dublê aceitável)
- Unlocks: None

**Código da fatia**: nenhum equivalente; construção do zero.
