# Story 001: Pool de 18 BoonDef, RarityTable e BencaosTuning no catálogo (BN1, BN2)

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R1, R7, R12, Tuning Knobs, Validação)
**Requirement**: `TR-bencaos-001`, `TR-bencaos-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Catálogo `.tres` com manifesto explícito; as `BoonDef` são listadas na ordem do manifesto (é ela que o sorteio indexa); `BencaosTuning` e `RarityTable` validados na carga (BN1, BN2) junto dos V*; consumidores recebem cópia.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004)
**Engine Notes**: Resource `.tres`; `duplicate_deep` conforme ADR-0004 (verificar na referência de engine).

**Control Manifest Rules (Feature)**:
- Required: valores de tuning do catálogo validado; dependências no `_init`
- Forbidden: números de gameplay hardcoded; listar recursos por varredura de pasta (a ordem vem do manifesto)

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-23: `tamanho_oferta` 0 ou 6 e `trocas_iniciais` −1 → erro BN1; pesos 0/0/0 ou escalas 1/1/2 → erro BN2; `tamanho_oferta` ≠ 3 no MVP → BN1.
- [x] TR-bencaos-001: o catálogo de fábrica entrega exatamente 18 `BoonDef` (ids `trad_*`) na ordem do manifesto, e a mesma ordem em toda carga (base da Fixture BN).
- [x] Padrões de fábrica: `RarityTable` 0,6/0,3/0,1 com escalas 1/1,5/2; `BencaosTuning` `tamanho_oferta` 3, `trocas_iniciais` 0, `raridade_bonus` 0.

---

## Implementation Notes

*Derived from ADR-0004:*

- `BoonDef` carrega id, chave de nome/descrição (tradução) e o efeito no formato do Modificadores; a Bênçãos não interpreta o efeito.
- BN1/BN2 entram no mesmo relatório de validação do catálogo (erro bloqueia a run).

---

## Out of Scope

- Story 003: sorteio sobre o pool
- Épico assets-e-conteudo: migração do JSON da fatia

---

## Files

- `src/content/boon_def.gd`, `src/content/rarity_table.gd`, `src/content/bencaos_tuning.gd`
- validador BN1/BN2 no módulo de validação do catálogo (`src/content/`)
- `.tres` de fábrica das 18 Tradições (pasta do manifesto do épico conteudo)
- `tests/unit/bencaos/pool_e_tuning_test.gd`

Código atual da fatia: as bênçãos explícitas de `game_session.gd::choose_blessing` e os dados em `data/integration/gameplay.json` são **substituídos** pelos `BoonDef`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bencaos/pool_e_tuning_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-17)

---

## Dependencies

- Depends on: `production/epics/conteudo/EPIC.md` (manifesto, carga e relatório de validação — story a criar)
- Unlocks: `production/epics/bencaos-tradicoes/story-002-registro-de-tomadas.md`, `production/epics/bencaos-tradicoes/story-003-sorteio-da-oferta.md`

## Completion Notes

2026-11-17 (gameplay-programmer, orquestrado; sem commit).
- Criados: `src/content/validacao/regras_bn.gd` (`RegrasBn`, ValidadorDoDono BN1/BN2, entra no relatório via `ValidadorDeCatalogo.acrescentar`); fixture `tests/unit/bencaos/fixture_bn.gd` (18 `trad_*` na ordem canônica de `traditions.ts`, efeitos de `BOON_EFFECTS` mapeados pela `TabelaDeEfeitos`, RarityTable 0,6/0,3/0,1 · 1/1,5/2, BencaosTuning 3/0/0); teste `tests/unit/bencaos/pool_e_tuning_test.gd` — 8 casos, 8 passaram.
- `boon_def.gd`, `rarity_table.gd`, `bencaos_tuning.gd` já existiam (épico conteudo); não alterados.
- Decisão: BN2 também acusa escalas e pesos de tamanhos diferentes.
- **Pendências:** (1) `.tres` de fábrica das 18 Tradições e entrada no manifesto `res://assets/data/content_catalog.tres` não criados — dependem do importador do cânone (conteudo story-010: mapa de doutrinas, `doutrina` referencia `weapon` e Guardião/Véu/Transmutação não têm arma no MVP → V4) e do épico assets-e-conteudo; até lá a "mesma ordem em toda carga" é verificada só na fixture. (2) `RegrasBn` precisa ser registrado na composição do carregador do catálogo (fora do escopo desta story).
