# Story 002: Tipos de definição do MVP como Resource (incl. Pactos)

> **Epic**: conteudo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R1, R1-P, R2-P)
**Requirement**: `TR-conteudo-001` (tipos e campos), `TR-conteudo-016` (CurseDef, BossPatternDef, Tunings de Pactos), `TR-conteudo-017` (mesmo id em CurseDef e EnemyDef; ids de espécie estáveis)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0003, ADR-0017, ADR-0013)
**ADR Decision Summary**: Classes de definição em `src/content/` como `Resource`; `WeaponDef` com exatamente 7 campos e `ataque`/`especial` como `AttackDef` embutidos; `BossPatternDef` embutido em `EnemyDef.padroes` (sem id e sem manifesto); tipos novos `CurseDef`, `MaldicoesTuning`, `VinculoTuning`, `ChefesTuning` (+ `TecnicaDef`, `SomDef`, `AudioTuning` propostos); índice por (tipo, id).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `Array[BossPatternDef]` tipado em `@export`; propriedade desconhecida no `.tres` é ignorada em silêncio pela engine (a checagem é da story 010).

**Control Manifest Rules (this layer)**:
- Required: definição `Resource` tratada como imutável em execução; ids de `CurseDef` append-only; campos conforme o esquema do GDD.
- Forbidden: texto de interface na definição (só chaves de tradução, R7); gameplay hardcoded.
- Guardrail: nenhum campo de apresentação pesado no grafo de dados.

---

## Acceptance Criteria

*Do GDD `design/gdd/conteudo-orientado-a-dados.md`:*

- [x] AC-53 (estrutura): o catálogo de fábrica do MVP instancia os 4 `CurseDef` (`vulto_mudo`, `espreitador_da_fenda`, `baluarte_de_cinza`, `soberano_do_limiar`), `MaldicoesTuning`, `VinculoTuning`, `ChefesTuning`, `WeaponDef pactos` e `EnemyDef soberano_do_limiar` com 4 `BossPatternDef`.
- [x] `CurseDef soberano_do_limiar` e `EnemyDef soberano_do_limiar` coexistem com o mesmo id (índice por tipo e id).
- [x] `WeaponDef` tem exatamente os 7 campos `id`, `doutrina`, `chave_nome`, `vida_max`, `velocidade`, `ataque`, `especial`.
- [x] Todos os tipos de R1/R1-P existem com os campos e unidades da tabela do GDD (conferido por teste que lista as propriedades `@export` de cada classe contra uma tabela esperada em arquivo de fixture).
- [x] AC-55 (estrutura): `HudTuning` tem 17 campos; `RunTuning.arma_padrao` aceita `pactos`.

---

## Implementation Notes

Um arquivo por classe em `src/content/` (nomes do GDD: `EnemyDef`, `WeaponDef`, `AttackDef`, `BoonDef`, `UpgradeDef`, `RegionDef`, `RewardTable`, `StatusTuning`, `InputTuning`, `HudTuning`, `TelaBencaoTuning`, `FeedbackTuning`, `TelemetriaTuning`, `RunTuning`, `BencaosTuning`, `VisualTuning`, `ArmasTuning`, `CurseDef`, `BossPatternDef`, `MaldicoesTuning`, `VinculoTuning`, `ChefesTuning`, `LinearCurveDef`, ...). A lista autoritativa e os campos são a R1/R1-P do GDD: ler a seção na implementação (não replicar de memória). Estado vivo é de `RefCounted` (ADR-0003), nunca nestas classes. Valores de fábrica para testes por funções de fábrica em `tests/` (sem número solto inline).

---

## Out of Scope

- Validação (stories 004/006); conteúdo real `.tres` (épico `assets-e-conteudo`).

---

## Files

- `src/content/*.gd` (um por tipo)
- `tests/unit/content/tipos_de_definicao_test.gd`, `tests/unit/content/fabricas_de_catalogo.gd` (helper de testes)

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/tipos_de_definicao_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/conteudo/story-001-esquema-e-relator.md`
- Unlocks: stories 003 a 010 deste épico; todos os épicos que leem definições

---

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

Arquivos criados (`src/content/`, um por classe): `weapon_def.gd`, `attack_def.gd`, `enemy_def.gd`, `boss_pattern_def.gd`, `linear_curve_def.gd`, `elite_rules.gd`, `effect_def.gd`, `boon_def.gd`, `rarity_table.gd`, `region_def.gd`, `reward_table.gd`, `economy_rates.gd`, `upgrade_def.gd`, `curse_def.gd`, `hud_tuning.gd` (17 campos), `tela_bencao_tuning.gd`, `feedback_tuning.gd`, `telemetria_tuning.gd`, `run_tuning.gd`, `bencaos_tuning.gd`, `armas_tuning.gd`, `status_tuning.gd`, `maldicoes_tuning.gd` (12), `chefes_tuning.gd` (13), `vinculo_tuning.gd`. Helpers de teste: `tests/unit/content/fabricas_de_catalogo.gd` (tabela esperada de campos + fábricas do MVP de Pactos + registros de chaves de fábrica) e `tests/unit/content/tabela_de_textos_em_memoria.gd`.

Testes: `tests/unit/content/tipos_de_definicao_test.gd` — 8 casos, 8 passaram. Cobre: campos `@export` de 25 classes contra a tabela de fixture; `WeaponDef` com exatamente os 7 campos; `HudTuning` com 17; catálogo de fábrica com 4 `CurseDef`, os 3 tunings de Pactos, `WeaponDef pactos`, `EnemyDef soberano_do_limiar` com 4 `BossPatternDef` e `anomalia_maior`; mesmo id em `curse` e `enemy`; `RunTuning.arma_padrao = pactos`; `Array[BossPatternDef]` tipado; `duplicate_deep(DEEP_DUPLICATE_ALL)` isola os padrões. Os "0 erros" do AC-53 estão no teste da story 004 (`test_catalogo_mvp_de_fabrica_passa_sem_erros`).

Decisões:
- Tipos do manifesto/índice: `weapon`, `enemy`, `boon`, `upgrade`, `region`, `curse`; únicos `elite_rules`, `rarity_table`, `reward_table`, `economy_rates`; todo `*Tuning` é `tuning` (id = nome snake, ex.: `hud_tuning`), como na R2-P (`tuning`, `maldicoes_tuning`).
- `obsoleto` é metadado da `DefinicaoBase` comum a todas; os "7 campos" do `WeaponDef` são os de conteúdo (o teste exclui `obsoleto`).
- `AttackDef`: params de geometria da forma num `Dictionary[StringName, float]` (`params`; nomes do Combate R3–R7) + `leque`/`atravessa` à parte; campos com unidade: `recarga_s`, `preparo_s`, `guarda_s`. `EnemyDef`: `raio_px`, `alcance_px`, `preparo_s`, `recarga_s`.
- Nomes provisórios do `CurseDef` (ataque básico, passivas, Chamado, habilidade) conforme R1-P/OQ 9: `forma_basica`, `alcance_basico_px`, `dano_basico`, `empurrao_basico`, `preparo_s`/`execucao_s`/`recuperacao_s`, `passivas`, `efeito_chamado`, `habilidade_unica`.
- Defaults dos scripts são neutros (0/vazio); nenhum número de gameplay no código.

Pendências reais:
- `InputTuning`, `VisualTuning`, `WaveRules` e os tunings de outros donos (`MovementTuning`, `CombatTuning`, `SealTuning`, `CameraTuning`, `ModifiersTuning`, `TelegraphTuning`, `IATuning`, `RoomTuning`) **não foram criados**: os campos vivem nos GDDs donos, não na R1/R1-P; ficam para os épicos donos (mesmo padrão: `extends DefinicaoBase`, tipo `tuning`). `TecnicaDef`, `SomDef`, `AudioTuning` (propostos pelos ADRs-0016/0017) também não.
- Faixas de V2 só onde o GDD de Conteúdo/donos dão o limite de formato (> 0, ≥ 0, y_floor ≤ y_cap); faixas dos donos ficam nos códigos da story 006.
