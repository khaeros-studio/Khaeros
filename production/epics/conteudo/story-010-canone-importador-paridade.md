# Story 010: Cânone, script de importação, paridade e validadores de CI (V5, V9, órfãos)

> **Epic**: conteudo
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R2, R5, R11, R2-P, R11-P)
**Requirement**: `TR-conteudo-005` (layout `assets/data/`; cópia canônica em CSV excluída do export), `TR-conteudo-013` (lista canônica só de leitura), `TR-conteudo-014` (script de importação F1–F6 em `tools/content-import/` com teste de paridade), `TR-conteudo-002` (append-only: registro de ids)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0013)
**ADR Decision Summary**: `tools/content-import/` converte as tabelas F1–F6 do cânone (CSV em `assets/data/canon/`, importador `keep`) em `.tres`, só em editor/CI; teste de paridade bloqueante em CI compara campo a campo e a impressão; V5 e V9 rodam só em debug/CI; propriedade desconhecida no `.tres` é erro, checada na leitura do texto do arquivo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: CSV com `importer="keep"` fora do export (EX-0004-NV); o Godot ignora propriedade desconhecida em silêncio, daí a leitura de texto do `.tres`; implementação do script é de `tools-programmer`.

**Control Manifest Rules (this layer)**:
- Required: importação só em editor/CI; teste de paridade em `tests/integration/content/`; ids append-only (V9) e registro `ids_registrados.csv`.
- Forbidden: executar o importador em runtime; editar a lista canônica pelo jogo.
- Guardrail: paridade e órfãos no CI sem rede.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-34 (paridade): fixture com valores brutos do cânone × `.tres` do importador: todo campo bate com F1–F6, casando pelo mapa de ids (R2), e o `valor` dos efeitos bate com `value × constante` (R1).
- [x] AC-39 (mapa): `trad_blade_traco_unico` tem `doutrina = lamina`; `RegionDef limiar` com chefe e pool corretos e a sequência `combate, combate, combate, santuario, combate, combate, chefe`; formas `arco` e `avanco` da `lamina`; `RewardTable` com `bencao`, `fragmentos`, `cura`, `provacao`; nenhum token canônico trocado pelo mapa sobra nos `.tres` (token inteiro, não substring); id canônico sem linha no mapa falha a importação citando o id.
- [x] AC-37 e AC-45: exatamente 18 ids `trad_*` com doutrina traduzida; `godot --headless --import` não gera `.translation` em `assets/data/canon/` e todo `.csv` ali tem `importer="keep"`.
- [x] AC-04: `.tres` em `assets/data/` fora do manifesto faz o teste de órfãos falhar citando o caminho, sem entrar no catálogo.
- [x] AC-13, AC-40, AC-60 (V5): nome "Traço Único" quando o canônico é "O Traço Único" erra; NFD × NFC passa; `ressonancia` para `lamina` erra; `Eco perdido`, `Laço dos Pactos`, `Vulto mudo` e "Criaturas" no lugar de "Maldições" erram.
- [x] AC-17 e AC-44, AC-60 (V9): `enemy,eco_perdido` ausente do catálogo erra; obsoleto passa; id sumido do manifesto ou linha a menos que o branch principal erra; sem a linha (`curse`, `baluarte_de_cinza`) erra.
- [x] AC-09 (preparo): definição que omite campo obrigatório e tem default no script é detectada pela leitura do texto do `.tres` (AC-AR-01: propriedade desconhecida ou campo ausente = erro de carga).
- [x] AC-20: o validador rodando no CI sobre o conteúdo real dá 0 erros.
- [x] AC-48: o manifesto real do MVP contém `EnemyDef anomalia_maior` (comportamento `chefe`) e `RegionDef limiar`; V4 dá 0 erros.

---

## Implementation Notes

Script em `tools/content-import/` (entrada: CSV canônico e `mapa_ids.csv`; saída: `.tres` na ordem do manifesto); `assets/data/` com layout da R5. Fixture com valores brutos em `tests/integration/content/fixtures/`. A produção dos `.tres` reais e o conteúdo final são do épico `assets-e-conteudo`; aqui entra o importador, a paridade e os validadores de CI. AC-38 (desempenho) está na story 003.

---

## Out of Scope

- Autoria do conteúdo (épico `assets-e-conteudo`); validadores V1–V4 (story 004).

---

## Files

- `tools/content-import/importar_canone.gd`, `mapa_ids.csv`, `ids_registrados.csv`
- `src/content/validacao/v5_nomes_canonicos.gd`, `v9_ids_registrados.gd`, `varredura_de_orfaos.gd`
- `tests/integration/content/paridade_do_canone_test.gd`, `orfaos_e_canone_test.gd`; `tests/unit/content/v5_v9_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/content/paridade_do_canone_test.gd` e `orfaos_e_canone_test.gd` — must exist and pass.

**Status**: [x] Created (`production/qa/evidence/assets-e-conteudo-evidence.md`)

---

## Dependencies

- Depends on: `story-004-validadores-v1-v11.md`, `story-005-unidades-f1-f8.md`, `story-008-impressao-canonica.md`, `production/epics/experimentos-de-engine/story-002-catalogo-e-cena.md`
- Unlocks: `production/epics/assets-e-conteudo/` (migração do JSON para `.tres`)
