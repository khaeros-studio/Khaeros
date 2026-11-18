# Story 008: Impressão canônica SHA-256 do catálogo

> **Epic**: conteudo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R12)
**Requirement**: `TR-conteudo-011` (impressão SHA-256 sobre serialização canônica na ordem do manifesto)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0005)
**ADR Decision Summary**: Serializador percorre só os campos declarados no esquema, ordenados por nome; protocolo de bytes: cabeçalho `KHAEROS-CATALOG`, tags de um byte, int64 LE, float64 LE com zero negativo normalizado e rejeição de NaN/infinito, UTF-8 com tamanho uint32; SHA-256 de 64 hex, forma curta com os 4 primeiros em maiúsculas.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `HashingContext` SHA-256 e paridade debug/release são NEEDS VERIFICATION (EX-0004-NV); congelar um vetor completo de bytes e hash antes de usar a impressão em telemetria.

**Control Manifest Rules (this layer)**:
- Required: impressão calculada ao fim de toda carga com 0 erros; ordem do manifesto e de arrays preservada; chaves de Dictionary ordenadas.
- Forbidden: metadados do editor, ids de instância e caminhos de script na entrada; ordem de iteração de `Dictionary` como fonte de ordem.
- Guardrail: custo de serialização medido e registrado.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria) e do ADR-0004:*

- [x] AC-46: dois catálogos de fábrica iguais têm impressões iguais; a curta tem 4 hex maiúsculos e é o começo da completa (64 hex); mudar um campo (0,25 → 0,26) muda a completa; trocar a ordem de duas definições no manifesto muda a completa; mudar só o texto traduzido não muda; −0,0 e 0,0 dão a mesma impressão.
- [x] O vetor de referência (bytes e hash) de um catálogo mínimo é congelado em fixture e coincide em teste; o mesmo vetor coincide entre debug e release.
- [x] Ciclo de sub-recursos, valor fora do esquema, NaN/infinito e contagem acima de uint32 são erros de serialização que impedem Pronto.
- [x] Sub-recurso compartilhado equivale a repetir seus valores; a versão do formato está no cabeçalho.
- [x] Impressão completa e curta expostas pelo `Catalogo` (story 007).

---

## Implementation Notes

Seguir exatamente a tabela do ADR-0004 §"Impressão canônica" (não a reproduzir de memória). A versão do protocolo muda quando a codificação mudar. A telemetria só consome a impressão após o vetor congelado (ADR-0004 §Impressão).

---

## Out of Scope

- Uso da impressão na seed/telemetria (épicos `rng`, `telemetria-local`).

---

## Files

- `src/content/impressao_canonica.gd`
- `tests/unit/content/impressao_canonica_test.gd`, `tests/unit/content/fixtures/vetor_canonico.*`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/impressao_canonica_test.gd` — must exist and pass.

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `story-003-carregador-e-manifesto.md`, `story-007-consulta-e-copia.md`, `production/epics/experimentos-de-engine/story-002-catalogo-e-cena.md`
- Unlocks: `story-009-recarga-e-tela-de-erros.md`; épico `rng` (contrato com a impressão)

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

`src/content/impressao_canonica.gd`: protocolo v1 do ADR-0004 (cabeçalho `KHAEROS-CATALOG` + u32 versão + u32 tipos; tags 0–7; int64/float64 LE; −0 normalizado; NaN/inf, objeto fora do esquema, ciclo e contagem > u32 são erros; sub-recurso expandido com tipo = classe e id vazio; chaves de Dictionary ordenadas como texto; campos ordenados por nome, `id`/`obsoleto` inclusos). O `CarregadorDeCatalogo` calcula a impressão ao publicar, e erro de serialização impede Pronto. `Catalogo.impressao_completa/curta`.
Vetor congelado: `tests/unit/content/fixtures/vetor_canonico.gd`, gerado por um codificador Python independente (hashlib), e o Godot 4.7.2 reproduz bytes e hash idênticos (`48b17c86…`). Teste `tests/unit/content/impressao_canonica_test.gd`: 10 casos, 10 passaram.
Pendências: a paridade debug × release precisa de build exportado (não executado). O custo de serialização ainda não foi medido (guardrail; fica no harness `tests/performance/content/`).
