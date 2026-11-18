# Story 004: Validadores V1–V4, V6–V8, V10 e V11

> **Epic**: conteudo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R2, R7, R8, R9, R8-P, R9-P)
**Requirement**: `TR-conteudo-002` (ids snake_case únicos por tipo), `TR-conteudo-007` (chaves de tradução; V6), `TR-conteudo-008` (dado só aponta para chaves registradas; V4), `TR-conteudo-017` (unicidade por tipo; mesmo id entre tipos)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Primeira passada coleta falhas de leitura, V1–V11 e regras por tipo; V1 verifica estrutura/tipos do recurso carregado (e a presença de campo na etapa de preparo, story 010); cada diagnóstico leva arquivo, campo, regra, valor e nível; dependência ausente já diagnosticada impede só o cálculo que a usa.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: V6 consulta as traduções importadas; V7 usa `ResourceLoader.exists` e o prefixo `assets/art/export/`.

**Control Manifest Rules (this layer)**:
- Required: validação igual em debug e release (exceto V5/V9); registros de chaves (comportamentos, status, tipos de sala) injetados pelos donos.
- Forbidden: lista de chaves hardcoded no validador; texto na definição.
- Guardrail: validação ≤ 30 ms para 30–60 definições.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-09 (V1): `EnemyDef` sem `dano` e outro listado como arma geram 2 erros V1; o segundo não entra no catálogo.
- [x] AC-10 (V2): `recarga = 0` erra e `preparo = 0` não, conforme a tabela de `AttackDef`.
- [x] AC-11 (V3): ids duplicados citando os dois caminhos, id `Lamina-1` erro de formato, `lamina` repetido entre tipos sem erro.
- [x] AC-12 (V4): referência a id inexistente, a chefe/status/tipo de efeito/comportamento/tipo de sala/recompensa fora do registro gera V4; lista de chaves não entregue gera "registro de chaves ausente".
- [x] AC-49: `chefe` reservado passa na V4; `voador` fora da lista é erro V4. AC-58: com o registro emendado, `chefe` é chave ativa e criar o inimigo não entrega erro ao relator.
- [x] AC-14 (V6): chave sem texto e chave com texto vazio geram 2 erros V6.
- [x] AC-15 (V7): ícone ausente e ícone fora de `assets/art/export/` geram 2 erros V7.
- [x] AC-16 (V8): pesos `[0,0,0]` e `[1,-1]` erram; `[0,1,0]` passa.
- [x] AC-18 e AC-42 (V10): "causa 12 de dano" erra; `{valor}` sem tipo erra; `{vida_max_plano.valor:int}` passa; `{valor:moeda}` erra; `{inexistente}` erra; `valor = -10` com `int` exibe "10".
- [x] AC-50 (V11): dois efeitos `recusas_morte` com `params.vida_ao_voltar` 0,4 e 0,5 geram 1 erro V11 citando as duas definições; iguais passam; efeitos diferentes passam.
- [x] AC-59 (V4 ampliada): fonte `vinculo:vulto_mudo` declarando `vida_max` passa; `cargas_esquiva` dá 1 erro V4.

---

## Implementation Notes

Um validador por regra (classe pequena, `Diagnostico` como saída), compostos pelo carregador (story 003). V5 e V9 (CI/debug) ficam na story 010; regras dos donos (ML/VP/CH/AV/RN...) na story 006. Não duplicar a lógica de F1–F8 (story 005); V2 chama as funções de unidades.

---

## Out of Scope

- V5, V9, órfãos, importador: story-010. Códigos dos donos e 2ª passada: story-006.

---

## Files

- `src/content/validacao/v1_estrutura.gd` … `v11_efeitos.gd`, `validador_de_catalogo.gd`
- `tests/unit/content/validadores_v1_v11_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/validadores_v1_v11_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: `story-002-tipos-de-definicao.md`, `story-003-carregador-e-manifesto.md`, `story-005-unidades-f1-f8.md`
- Unlocks: `story-006-validacao-dos-donos.md`, `story-010-canone-importador-paridade.md`

---

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

Arquivos criados (`src/content/validacao/`): `validador_de_regra.gd` (`@abstract`), `v1_estrutura.gd`, `v2_faixas.gd`, `v3_ids.gd`, `v4_referencias.gd`, `v6_textos.gd`, `v7_arte.gd`, `v8_pesos.gd`, `v10_descricoes.gd`, `v11_efeitos.gd`, `validador_de_catalogo.gd` (compõe a 1ª passada; `acrescentar()` para os donos na story 006), `registros_de_chaves.gd` (registros dos donos, ativas/reservadas), `tabela_de_textos.gd` (`@abstract`), `verificador_de_arte.gd` (`ResourceLoader.exists`).

Testes: `tests/unit/content/validadores_v1_v11_test.gd` — 20 casos, 20 passaram. Cobertura: catálogo de fábrica do MVP com 0 erros (AC-53, parte V1–V11); AC-09 (dano ausente com default do script + inimigo listado como arma: 2 erros V1, o segundo fora do catálogo); AC-10; regra entre campos `y_floor > y_cap`; AC-11; AC-12 (inimigo, chefe, status, tipo de efeito, comportamento, tipo de sala `combta`, tipo de recompensa e "registro de chaves ausente"); AC-49; AC-58 (parte V4: `chefe` ativo, não reservado); AC-59; AC-14 (+ chave derivada `_DESC`); AC-15; AC-16; AC-18/AC-42 (literal, `{valor}`, `{inexistente}`, `{vida_max_plano.valor:int}`, `{valor}` sem tipo, `{valor:moeda}`, `{status.abalo.reducao_dano_causado:pct}`, `-10` com `int` → "10"); AC-50.

Decisões:
- Validadores genéricos: leem só o esquema declarativo (story 001); nenhuma lista de chaves no validador (registros injetados pelos donos).
- V1 em runtime: tipo da definição × tipo do manifesto, sub-recurso/texto/lista obrigatórios vazios; presença de campo gravado quando o item a traz (etapa de preparo).
- V2 lê faixas e regras entre campos do esquema; V8 dá um erro por tabela (negativo ou soma ≤ 0).
- V4 da fonte `vinculo:<curse_id>` é `V4Referencias.validar_fonte_vinculo()` sobre o registro `atributos_portador_maldicao` (o código V4 segue o "[a confirmar]" do GDD).
- V10: `num` com 1 casa usa vírgula PT-BR ("1,5") — o GDD não fixa o separador; `formatar()` é estático para o dono reutilizar.

Pendências reais:
- V2 "≥ 1 passo" (F7) depende da story 005 (unidades), que não é minha; quando chegar, V2 passa a chamar as funções de unidades.
- AC-58 parte "criar o inimigo não entrega erro ao relator" é do dono (IA).
- Implementação de jogo de `TabelaDeTextos` sobre a tradução importada: não feita (API do TranslationServer 4.7 não conferida no engine-reference); V5/V9: story 010.
