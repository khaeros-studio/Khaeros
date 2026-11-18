# Story 005: A acuada — nascimento, neutralidade, alvo por paridade, ferir_acuada e fuga

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (C. Encontro de pacto, V7, V8, V12; F2)
**Requirement**: `TR-vinculo-005`, `TR-vinculo-006`, `TR-vinculo-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0017: Aliados e invocações (§11)
**ADR Decision Summary**: A acuada é entidade neutra e imóvel, fora da câmara limpa e sem fogo amigo; o único dano é `ferir_acuada` (dano inteiro, sem hitstop, aplica `M` do atacante); com Vida ≤ 0 o Combate chama `falhar_encontro` de forma síncrona antes da varredura. Cada inimigo guarda `alvo_padrao` fixado no nascimento pela paridade da ordem na onda (par → acuada); `alvo_efetivo` prioriza atração da Maldição, depois acuada se `acuada_atingivel()`, depois o jogador; o golpe testa só o alvo travado; na fuga, quem ainda roda no item 7 já lê o jogador.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0010)
**Engine Notes**: Sem física na regra.

**Control Manifest Rules (Feature/Core)**:
- Required: tudo por `player_id`; congelamento por passo vivo (nada avança em hitstop, pausa e Transição)
- Forbidden: separação incluir a acuada (ADR-0018); expor `InimigoRef`
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-07 (V7, F2): encontro com `espreitador_da_fenda` e sem pedra em `(960; 540)` → a acuada nasce lá com `Vida = 114`, `encontros_vistos` +1, `primeiro_encontro_visto = true`.
- [x] AC-VP-08 (V7): Virote, Selo e Chamado na área da acuada (`114`) com inimigo encostado → Vida continua 114.
- [x] AC-VP-09 (V8): onda de 3 Ecos → ordem 0 e 2 miram a acuada, ordem 1 o jogador; golpe do Eco 0 com o jogador na forma fere só a acuada.
- [x] AC-VP-10 (V8): Eco 0 atraído pelo Chamado por 180 passos → mira a Maldição nesse tempo e volta à acuada no passo 181.
- [x] AC-VP-11 (V12): acuada com `Vida = 5` recebe 9 → `Fugiu`, sai em 12 passos, quem a mirava passa ao jogador no mesmo passo, `encontro_pendente = [especie]`, a câmara limpa e abre portas sem esperar `pacto_resolvido`.
- [x] AC-VP-02 (V5, V21): run com a Lâmina → fluxo `pactos` não é pedido e nenhuma acuada nasce.

---

## Implementation Notes

- `ao_montar_camara(indice, montador)` nasce a acuada se o encontro está `Planejado` em `indice` (sem RNG).
- `acuada_atingivel()` e `alvo_padrao` expostos à IA por interface (dependência só por porta, como ADR-0017/0018).
- Emite `EvEncontroFalhou` na falha.

---

## Out of Scope

- Consentimento e portas 2b: story 006. Visual da acuada (VP-V1–V3): épicos `pipeline-visual`/`feedback-de-combate`.

---

## Files

- `src/gameplay/vinculo/acuada.gd`, `vinculo.gd` (`ao_montar_camara`, `falhar_encontro`)
- `tests/integration/vinculo/acuada_alvo_e_fuga_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/vinculo/acuada_alvo_e_fuga_test.gd`
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-004-sorteio-do-encontro.md`; `production/epics/maldicoes/story-008-chamado-do-pacto-e-atracao.md`; épicos `production/epics/combate-nucleo/` (`ferir_acuada`), `production/epics/ia-de-inimigos-e-elites/` (`alvo_efetivo`), `production/epics/camaras-e-ondas/` (ordem de nascimento)
- Unlocks: `production/epics/vinculo-e-pactos/story-006-consentimento-portas-e-dupla.md`
