# Story 002: Definições de armas (WeaponDef/AttackDef) e inimigos (EnemyDef)

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R1); `design/gdd/armas-das-doutrinas.md` (R4, R8); `design/gdd/ia-de-inimigos-e-elites.md` (catálogo)
**Requirement**: N/A — sem TR próprio; os dados são validados pelos TRs de `armas-das-doutrinas` (TR-armas-001, TR-armas-008) e `ia-de-inimigos-e-elites`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (emendas de 2026-11-16)
**ADR Decision Summary**: `WeaponDef` tem exatamente 7 campos (`id`, `doutrina`, `chave_nome`, `vida_max`, `velocidade`, `ataque`, `especial`); `ataque`/`especial` são `AttackDef` **embutidos**, forma `chamado` só no slot `especial`; propriedade desconhecida no `.tres` é erro de carga. Descrições são chave derivada `<chave_nome>_DESC`. Caminhos de arte são texto.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: o Godot ignora propriedade desconhecida em silêncio — a checagem é no texto do `.tres` em editor/CI.

**Control Manifest Rules (Foundation)**:
- Required: definições do catálogo são `Resource` tratadas como imutáveis; esquema com campos e limites
- Forbidden: importador em runtime
- Guardrail: validação ≤ 30 ms

---

## Acceptance Criteria

*From the epic scope and ADR-0004 emendas:*

- [x] Três `WeaponDef` do MVP (Lâmina, Ressonância, Besta do Vínculo) com 7 campos e `AttackDef` embutidos; *Chamado do Pacto* só no `especial` da Besta.
- [x] `EnemyDef` dos inimigos do Limiar da fatia (Eco Perdido, Anomalia Menor, Fenda Errante, peças de elite) com valores iguais aos de `gameplay.json` / GDD de IA; caminhos de arte apontando para `assets/art/runtime/<ator>/`.
- [x] Chaves de nome e `_DESC` presentes no CSV de tradução (V6 passa).
- [x] Carregador chega a Pronto sem erro; smoke check registrado.

---

## Implementation Notes

*Derived from ADR-0004:*

- Entradas acrescentadas no fim do manifesto, por tipo.
- Nenhum valor novo de balanço: só migração; mudança de número exige o GDD dono.

---

## Out of Scope

- Story 004: `EnemyDef soberano_do_limiar` com `BossPatternDef`
- Story 006: os atlas de arte

---

## Files

- `assets/data/armas/*.tres`, `assets/data/inimigos/*.tres` (novos); `assets/data/content_catalog.tres` (acrescentar)
- `assets/i18n/conteudo.csv` (chaves de nome/descrição)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`)
**Status**: [x] Created (`production/qa/evidence/assets-e-conteudo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/assets-e-conteudo/story-001-manifesto-e-tunings-da-fatia.md`
- Unlocks: `production/epics/assets-e-conteudo/story-003-bencaos-regioes-e-camaras.md`
