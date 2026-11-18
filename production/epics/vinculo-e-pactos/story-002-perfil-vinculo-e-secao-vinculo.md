# Story 002: PerfilVinculo e o conteúdo da seção `[vinculo]` (escrever/ler/campos_de_ids)

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (A. Perfil de vínculo; H. Contrato com Save e perfil, V30–V33; I. Injeção)
**Requirement**: `TR-vinculo-001`, `TR-vinculo-015`, `TR-vinculo-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP; ADR-0015: Ciclo da run e composição; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `PerfilVinculo` é de escopo perfil (`SessaoDeJogo`), injetado, escrito só pelo Vínculo; o conteúdo vai para `user://perfil.cfg` `[vinculo]` pelo `RepositorioDePerfil` (gravação atômica com `.bak`). `escrever()` só `bool`/`int`/`String`/`Array`/`Dictionary`, espécies na ordem do manifesto; `ler()` corrige só a entrada afetada, aviso `VP-S1` uma vez por chave, nunca trava; nível é cache da F3.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0013: só o `ArmazemUserGodot` toca `FileAccess`/`DirAccess`; testes com `ArmazemEmMemoria`.

**Control Manifest Rules (Feature)**:
- Required: escopos — menor referencia maior, nunca o contrário; gravação do perfil só em `gravar_se_pendente` (estado ≠ JOGO) ou `sair_do_jogo()`
- Forbidden: Autoload; `float` ou `StringName` no conteúdo gravado
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-24 (V31, V33): `ler()` com `nivel = 7` e `vinculo_pontos = 55` numa espécie pactuada e `ultima_dupla = ["vulto_mudo","vulto_mudo"]` → `nivel = 3`, `ultima_dupla = ["vulto_mudo"]`, dois avisos `VP-S1`; `escrever()` só tem `bool`, `int`, `String`, `Array`, `Dictionary`, espécies na ordem do manifesto.
- [x] AC-VP-25 (V31): `campos_de_ids()` devolve `["ultima_dupla", "encontro_pendente"]`.
- [x] AC-VP-02 (V5, V21, parte de perfil): uma run inteira com a Lâmina deixa `escrever()` igual ao de antes.

---

## Implementation Notes

- `PerfilVinculo` guarda por espécie `pactuada`, `nivel`, `vinculo_pontos`, `encontros_vistos`, `encontros_bem_sucedidos`, e os campos globais (`primeiro_pacto_concedido`, `primeiro_encontro_visto`, `runs_pactos_sem_encontro`, `runs_pactos_iniciadas`, `encontro_pendente`, `ultima_dupla`).
- Variante `VinculoNulo` com `return` explícito em todo override (ADR-0015).

---

## Out of Scope

- Repositório, `.bak` e gatilhos de gravação: épico `production/epics/persistencia/`.

---

## Files

- `src/gameplay/vinculo/perfil_vinculo.gd`, `vinculo_nulo.gd`
- `tests/unit/vinculo/perfil_vinculo_e_secao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/vinculo/perfil_vinculo_e_secao_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-001-vinculo-tuning-e-validacao-vp.md`; épico `production/epics/persistencia/` (`RepositorioDePerfil`)
- Unlocks: stories 003, 004, 007 deste épico
