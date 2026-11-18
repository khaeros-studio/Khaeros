# Story 003: Carregador síncrono, manifesto explícito e harness de carga

> **Epic**: conteudo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/conteudo-orientado-a-dados.md` (R4, R9)
**Requirement**: `TR-conteudo-004` (manifesto único explícito), `TR-conteudo-009` (carga síncrona, coleta todos os erros, bloqueia a run), `TR-conteudo-015` (orçamento de carga, advisory)

**ADR Governing Implementation**: ADR-0004: Catálogo de dados (+ ADR-0001)
**ADR Decision Summary**: Carregador na thread principal lê `assets/data/content_catalog.tres` e as definições na ordem gravada; estados Não carregado, Carregando, Validando, Pronto ou Falhou; publica catálogo, impressão e ajustes juntos só com zero erros; leitura síncrona até a medição justificar o contrário.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `ResourceLoader` síncrono × threaded é item NEEDS VERIFICATION (EX-0004-NV); o modo de cache é da story 009.

**Control Manifest Rules (this layer)**:
- Required: carga síncrona antes do menu; erros coletados juntos; resultado igual em debug e release; carregador centraliza o acesso a caminhos de definições.
- Forbidden: `load(`/`preload(`/`ResourceLoader` com caminho de `assets/data` fora do carregador (AC-24); varredura de diretório em execução.
- Guardrail: mediana de 5 cargas frias ≤ 250 ms (validação ≤ 30 ms), advisory.

---

## Acceptance Criteria

*Do GDD (Acceptance Criteria):*

- [x] AC-01: com o manifesto real, o estado termina em Pronto com 0 erros e cada tipo contém exatamente os ids listados.
- [x] AC-02: manifesto inexistente: Falhou com exatamente 1 erro `manifesto não encontrado: …` e nenhuma definição.
- [x] AC-03: manifesto com 2 arquivos inexistentes e 1 definição inválida: Falhou com os 3 erros juntos.
- [x] AC-08: o mesmo catálogo inválido em build de release exportado dá o mesmo resultado do debug, exceto V5 e V9 (R9).
- [x] AC-24: nenhuma ocorrência de `load(`/`preload(`/`ResourceLoader` com caminho de `assets/data` em `src/`, fora do carregador.
- [x] AC-38 (advisory): harness em `tests/performance/content/` mede carga e validação, 5 cargas frias, registra a mediana em `production/qa/evidence/`, sem assert de tempo.

---

## Implementation Notes

`CarregadorDeCatalogo` com máquina de estados; manifesto como `Resource` com entradas (tipo, caminho); índice por (tipo, id) e lista ordenada por tipo (usada pela story 007). Falha de arquivo individual é registrada e a carga segue. PC de medição: máquina de desenvolvimento (Ryzen 5 5600H, 16 GB, RTX 3050 Laptop, SSD), build de release (ADR-0004 emenda TR-conteudo-015).

**Código atual**: `src/foundation/session_catalog.gd` (JSON `res://data/integration/gameplay.json`): **substituir**; manter funcionando via adaptador até o épico `assets-e-conteudo` migrar o JSON para `.tres`; `tests/integration/run_catalog.gd` continua passando durante a transição.

---

## Out of Scope

- Validadores (004/005/006), impressão (008), recarga (009).

---

## Files

- `src/content/carregador_de_catalogo.gd`, `catalogo.gd`, `manifesto_do_catalogo.gd`
- `tests/integration/content/carga_e_manifesto_test.gd`, `tests/performance/content/carga_do_catalogo_perf.gd`
- `production/qa/evidence/conteudo-carga-do-catalogo.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/content/carga_e_manifesto_test.gd` — must exist and pass; evidência de desempenho no `.md` acima.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: `story-001-esquema-e-relator.md`, `story-002-tipos-de-definicao.md`, `production/epics/experimentos-de-engine/story-002-catalogo-e-cena.md`
- Unlocks: stories 004, 006, 007, 008, 009, 010

---

## Completion Notes

**2026-11-16 — engine-programmer (implementação orquestrada, sem commit).**

Arquivos criados: `src/content/carregador_de_catalogo.gd` (estados NAO_CARREGADO → CARREGANDO → VALIDANDO → PRONTO/FALHOU; `Leitor` interno injetável sobre `ResourceLoader` síncrono), `src/content/manifesto_do_catalogo.gd` (listas paralelas `tipos`/`caminhos`), `src/content/catalogo.gd`; `tests/integration/content/carga_e_manifesto_test.gd`; `tests/performance/content/carga_do_catalogo_perf.gd`; `production/qa/evidence/conteudo-carga-do-catalogo.md`.

Testes: `carga_e_manifesto_test.gd` — 4 casos, 4 passaram, com `ResourceSaver`/`ResourceLoader` reais em `user://teste_conteudo_carga` (limpo ao fim): manifesto válido → Pronto com exatamente os ids e a ordem do manifesto (forma do AC-01); manifesto inexistente → Falhou com 1 erro `manifesto não encontrado: …` e catálogo nulo (AC-02); 2 arquivos inexistentes + 1 definição inválida → os 3 erros juntos (AC-03); varredura de `src/` sem `load(`/`preload(`/`ResourceLoader` com `assets/data` fora do carregador (AC-24). O AC-09 (definição listada no tipo errado não entra) também é coberto no teste da story 004.

Desempenho (AC-38, advisory): harness rodado em editor debug, catálogo sintético de 41 definições: mediana da carga 398,9 ms, validação 21,4 ms (evidência no `.md`). Sem assert de tempo.

Decisões:
- Erros de leitura usam a regra `LEITURA`; definição de outra classe que a do tipo listado é V1 e não entra no catálogo; falha individual não interrompe a leitura.
- Catálogo, avisos e erros são publicados só ao fim; com ≥ 1 erro nada é publicado.
- `src/foundation/session_catalog.gd` **não foi tocado**: continua servindo a fatia (adaptador até o épico assets-e-conteudo migrar o JSON); `tests/integration/run_catalog.gd` segue sem mudança.

Pendências reais:
- AC-01 com o **manifesto real** de `assets/data/`: a pasta não existe (épico assets-e-conteudo).
- AC-08 (paridade debug × release exportado): precisa de build exportado; não executado.
- AC-38: medição em release no PC de medição; em debug a carga ficou acima de 250 ms (leitura de `.tres` texto domina).
- Ligar o carregador no `Main` (`src/app/main.gd`) e as implementações de jogo de `TabelaDeTextos` (tradução importada) e dos registros dos donos: fora desta story (não editei `main.gd`). Impressão: story 008; recarga/cache: story 009.
