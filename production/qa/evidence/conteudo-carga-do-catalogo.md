# Evidência — carga do catálogo (AC-38, TR-conteudo-015) — ADVISORY

**Story:** production/epics/conteudo/story-003-carregador-e-manifesto.md
**Data:** 2026-11-16
**Harness:** `tests/performance/content/carga_do_catalogo_perf.gd`
(`godot --headless --path . -s res://tests/performance/content/carga_do_catalogo_perf.gd`)

## Condições

- Godot 4.7.2 standard, **editor headless, build de debug** (`OS.is_debug_build() = true`).
  **Não é** a condição do orçamento (build de release exportado no PC de medição, ADR-0004).
- Catálogo **sintético de fábrica**, 41 definições (fábricas de `tests/unit/content/`:
  3 armas, 27 inimigos, chefe com 4 padrões, 4 espécies, região, 5 tunings). O catálogo
  real de `assets/data/` ainda não existe (épico assets-e-conteudo).
- 5 cargas frias: cada rodada lê uma cópia em pasta própria de `user://` (nenhum caminho
  no cache do ResourceLoader). `.tres` em texto.
- Carga total = `CarregadorDeCatalogo.carregar()` (manifesto + leitura + 1ª passada V1–V11).
  Validação = `ValidadorDeCatalogo.validar()` medido à parte sobre os mesmos itens.

## Resultado

| Rodada | Carga total (ms) | Validação (ms) |
|---|---|---|
| 0 | 384,4 | 23,0 |
| 1 | 414,5 | 21,4 |
| 2 | 473,3 | 31,5 |
| 3 | 398,9 | 14,1 |
| 4 | 255,6 | 11,6 |
| **Mediana** | **398,9** | **21,4** |

Meta (advisory): mediana ≤ 250 ms, validação ≤ 30 ms.

## Leitura

- Validação: 21,4 ms de mediana, dentro da meta mesmo em debug.
- Carga total: 398,9 ms em debug, **acima** da meta de 250 ms. Quase tudo é leitura de
  `.tres` em texto pelo ResourceLoader (validação ≈ 5% do total). Não fecha nem reprova o
  orçamento: falta medir em build de release exportado, onde o export converte texto para
  binário por padrão (não verificado aqui). Pendência: repetir com o catálogo real em
  release; se seguir acima, avaliar `.res` binário antes de carga assíncrona (EX-0004-NV).
- Saída do harness termina com `17 resources still in use at exit`: cache estático de
  esquemas (`EsquemaDeDefinicao._cache`, por Script), esperado num `-s` script; não afeta
  a medição.
