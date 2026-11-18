# Story 006: Consentimento no estado Bênção, Portas 2b e a dupla que cresce

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (V9, V10, V11, V13, V15)
**Requirement**: `TR-vinculo-008`, `TR-vinculo-009`, `TR-vinculo-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição; ADR-0017: Aliados e invocações (§12); ADR-0001; ADR-0002; ADR-0012; ADR-0013
**ADR Decision Summary**: A tela de consentimento abre no estado `BENCAO` com o mundo parado; a escolha chega como evento de UI fora do passo. "Oferecer" emite `pacto_registrado(especie_id)`, o perfil fica pendente e grava no fim do mesmo passo (estado ≠ JOGO); depois sai `pacto_resolvido` e as Portas seguem ao passo 3. A recompensa sai primeiro; as Portas esperam `pacto_resolvido` (passo 2b). Com dupla de 1, o Vínculo chama `acrescentar_a_dupla(player_id, def, min(vida_acuada, vida_max))`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0001/0002/0012) / LOW (ADR-0015, 0017)
**Engine Notes**: Lógica; a tela visual é a story 010.

**Control Manifest Rules (Feature)**:
- Required: gravação do perfil só em `gravar_se_pendente`; Portas consultam `run.ativa()` antes de conceder
- Forbidden: `SceneTree.paused`; a Run gravar disco
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-12 (V9, Portas 2b): câmara do encontro limpa com a acuada viva e recompensa de bênção → ao fechar a Tela de bênção as portas continuam fechadas até a escolha no consentimento.
- [x] AC-VP-13 (V10): `espreitador_da_fenda` não pactuado em `Aguardando`, "Oferecer o vínculo" → `pactuada = true`, `nivel = 1`, `encontros_bem_sucedidos = 1`, `pacto_registrado("espreitador_da_fenda")`, Save grava no mesmo ponto seguro e as portas abrem.
- [x] AC-VP-14 (V13): `baluarte_de_cinza` com `encontros_bem_sucedidos = 0` → a tela mostra só "Ela voltará", `encontros_bem_sucedidos = 1`, `encontro_pendente = ["baluarte_de_cinza"]`, sem pacto; a próxima run de Pactos planeja o Baluarte; no 2º sucesso a tela oferece o vínculo.
- [x] AC-VP-15 (V15): dupla só com `vulto_mudo` e acuada `espreitador_da_fenda` com `Vida = 80` → *Espreitador* na reserva `Pronta` com `80/95` e Troca aceita quando a recarga é 0.

---

## Implementation Notes

- `encontro_aguardando()` consultado pelas Portas; "Reafirmar o vínculo (+6)" para espécie já pactuada (V11).
- O caso de "Deixá-la ir" mantém `encontro_pendente` conforme V10/V11.

---

## Out of Scope

- Tela visual: story 010. Pontos da run: story 007.

---

## Files

- `src/gameplay/vinculo/consentimento.gd`, `vinculo.gd`
- `tests/integration/vinculo/consentimento_portas_e_dupla_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/vinculo/consentimento_portas_e_dupla_test.gd`
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-005-acuada-alvo-e-fuga.md`; `production/epics/maldicoes/story-006-contadores-regeneracao-e-dupla-que-cresce.md`; épicos `production/epics/portas-e-recompensas/` (passo 2b), `production/epics/persistencia/` (`GravadorDePerfil`)
- Unlocks: `production/epics/vinculo-e-pactos/story-007-pontos-niveis-e-consolidacao.md`, `production/epics/vinculo-e-pactos/story-010-telas-do-pacto.md`
