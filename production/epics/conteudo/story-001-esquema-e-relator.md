# Story 001: Esquema de definição, diagnóstico e relator de erros injetável

> **Epic**: conteudo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R1, R3, R9, R10)
**Requirement**: `TR-conteudo-001` (esquema), `TR-conteudo-010` (relator injetado)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: O esquema de cada definição declara campos de conteúdo, tipos, obrigatoriedade, limites, defaults permitidos e regras entre campos; o diagnóstico guarda arquivo, campo, regra, valor e nível; o relator padrão registra e sinaliza, com parada opcional em debug; o relator de testes acumula.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `Resource` com `@export` tipados; a presença de campo gravado × default do script não é visível após a materialização do `Resource` (ADR-0004 §Validação).

**Control Manifest Rules (this layer)**:
- Required: esquema declara campos, tipos, obrigatoriedade, limites e regras entre campos; validação distingue campo ausente de valor gravado; tudo injetado.
- Forbidden: singleton/`Autoload` do catálogo; leitura de `assets/data` fora do carregador.
- Guardrail: validação ≤ 30 ms (advisory, AC-38).

---

## Acceptance Criteria

*Do GDD (AC-21, AC-43) e do ADR-0004:*

- [x] Pedido de id inexistente devolve `null` e o relator falso recebe tipo, id e solicitante; `existe()` responde `false` sem registrar erro (AC-21), e o relator falso não chama `assert`.
- [x] Relator padrão com `parar_em_debug = false` e log falso escreve uma linha com tipo, id e solicitante, sem interromper (AC-43).
- [x] `Diagnostico` guarda arquivo, campo, regra, valor encontrado e nível (erro/aviso); a lista é ordenada por tipo, posição no manifesto, regra e campo.
- [x] O esquema aceita declarar obrigatoriedade e limites por campo, e distingue "campo ausente no arquivo" de "default do script" (base de AC-09).

---

## Implementation Notes

Classes em `src/content/`: `DefinicaoBase` (`Resource`: `id`, `obsoleto`), `EsquemaDeDefinicao` (dados declarativos, não regras de V1–V11), `Diagnostico`, `RelatorDeErros` (`@abstract`/interface) com `RelatorPadrao` e `RelatorAcumulador`. Construtores aceitam defaults do editor. Reaproveitar só como referência os helpers de faixa e finitude (`_number`, `_finite`, `_fields`) de `src/foundation/session_catalog.gd`; o arquivo é **substituído** na story 003 e removido ao fim do épico.

---

## Out of Scope

- story-002: tipos concretos; story-004/006: regras de validação; story-007: consulta do catálogo.

---

## Files

- `src/content/definicao_base.gd`, `esquema_de_definicao.gd`, `diagnostico.gd`, `relator_de_erros.gd`
- `tests/unit/content/relator_e_esquema_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/relator_e_esquema_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: None
- Unlocks: `story-002-tipos-de-definicao.md`, `story-003-carregador-e-manifesto.md`, `story-007-consulta-e-copia.md`

---

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

Arquivos criados (`src/content/`): `dado_de_conteudo.gd` (base comum de definições e sub-recursos), `definicao_base.gd`, `esquema_de_definicao.gd`, `diagnostico.gd`, `relator_de_erros.gd` (`@abstract`, com `RelatorDeErros.Entrada`), `relator_padrao.gd`, `relator_acumulador.gd`, `item_do_catalogo.gd`; `catalogo.gd` (obter/existe/listar mínimos, usados pelo AC-21; arquivo da story 003, a story 007 completa filtrar e cópias).

Testes: `tests/unit/content/relator_e_esquema_test.gd` — 9 casos, 9 passaram (gdUnit4, 0 erros, 0 órfãos).

Decisões:
- O esquema é **derivado** das propriedades `@export` (tipo) e completado por `_declarar_regras()` de cada classe (obrigatoriedade, faixa, aceita zero, default permitido, referência a tipo/registro, chave de texto, descrição, arte, pesos) + regras entre campos. Cacheado por Script (não thread-safe; thread principal).
- Campo ausente × default do script: `EsquemaDeDefinicao.campos_gravados_no_texto()` lê a seção `[resource]` de um `.tres` e `campos_ausentes()` compara. Atenção: o Godot não grava propriedade igual ao default, por isso campos cujo zero é válido levam `aceita_default()`; a verificação de presença real (do arquivo de origem/CSV) é da etapa de preparo (story 010).
- `RelatorPadrao` recebe o destino do log como `Callable` e `parar_em_debug`; usa `assert` (que só existe em debug), sem ler `OS`.
- Ordem natural de regra na ordenação de diagnósticos (V2 antes de V10).

Pendências: nenhuma desta story.
