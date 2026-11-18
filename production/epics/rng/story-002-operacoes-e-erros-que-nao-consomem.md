# Story 002: Operações F5–F8 e erros que não consomem

> **Epic**: RNG com seed
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico
**ADR Decision Summary**: Cada operação tem consumo definido; argumentos e validade são verificados antes do primeiro avanço; pedido inválido gera diagnóstico no relator injetado e conserva a sequência.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Aritmética inteira de 64 bits. O caminho ponderado inteiro até W = 2³¹ usa `bucket = (u * W) >> 32`; o caso de borda de arredondamento do caminho real "merece vetor específico na implementação" (ADR-0005).

**Control Manifest Rules (this layer)**:
- Required: argumentos validados antes do primeiro avanço; pedido inválido gera diagnóstico e conserva a sequência (ADR-0005)
- Forbidden: calcular diferença que possa estourar int64 sem validar o intervalo antes (ADR-0005)
- Guardrail: n > 2²¹ recusado antes de alocar ou consumir (ADR-0005)

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [ ] **AC-11** F5: a=5, b=10, u=`80000000` → 8; a=2,0, b=4,0, u=`40000000` → 2,5; a=b=7 → 7 e consome 1; com u=`FFFFFFFF`, vr < b
- [ ] **AC-12** F6 a partir de `B0B08409`: `[3,2,1]` → 0 e `[0,5,0,1]` → 1, consumindo 1; com u=0 e u=`FFFFFFFF`, `[0,5,0,1]` → 1 e 3 (peso 0 nunca sai); pesos `[1, 2.5]` vão pelo caminho real
- [ ] **AC-13** F7 a partir de `B0B08409`: n=8, k=3 → `[1,6,7]` com estado final `F832F1E8`; n=2, k=5 → 2 índices distintos, consome 2; k=0 ou n=0 → `[]` sem mudar o estado
- [ ] **AC-14** F8 a partir de `B0B08409` sobre `[0…9]` → `[3,6,2,4,0,5,9,8,7,1]`, estado final `8737CDA6`, lista original intacta; n ≤ 1 → cópia, consome 0
- [ ] **AC-15** Erros não consomem (F4(0), F4 com n > 2²¹, F5 com a > b, F6 com lista vazia, peso negativo, NaN, ±INF, W = 0 ou soma inteira > 2³¹): valor previsto (0 / a / −1), exatamente 1 registro no relator, estado idêntico e a próxima saída é a que viria sem o erro
- [ ] **AC-16** F7 com n = k = 200 consome exatamente 200 números

---

## Implementation Notes

*Derived from ADR-0005 (Decision: Operações e limites; Escolha ponderada inteira no limite):*

Tabela de consumo: real unitário 1 avanço; inteiro 0..n−1 1 avanço com 1 ≤ n ≤ 2²¹; intervalo inteiro ou real 1 avanço (inclusive extremos iguais, regras de F5); escolha ponderada 1 avanço após validar todos os pesos e a soma; k distintos de n por Fisher–Yates parcial (F7), min(k,n) avanços; embaralhar cópia (F8), max(n−1,0) avanços, preservando a lista recebida. F7 e F8 usam F4. Para n acima de 2²¹ a operação é recusada antes de alocar ou consumir; n ou k negativos são inválidos; n=0 ou k=0 de F7 devolvem vazio sem consumir. Valores reais e somas devem ser finitos antes de sortear. Pesos inteiros: valida-se que cada peso cabe em `2³¹ − soma_atual`; havendo qualquer peso real, usa-se o caminho real de F6 e o arredondamento que alcance W devolve o índice positivo final. Os limites de coleção e o caso de arredondamento são extensões técnicas propostas pelo ADR: registrar vetor próprio para cada um.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: F1–F4 e derivação F2
- Story 003: fonte que injeta o relator e distribui fluxos
- Story 005: consumo fixo por dono (spawn com 14 candidatos)

---

## Files

- `src/foundation/rng/fluxo_rng.gd` (operações F5–F8)
- `src/foundation/rng/relator_de_erros_rng.gd` (interface do relator injetado)
- `tests/unit/rng/operacoes_e_erros_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/rng/operacoes_e_erros_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/rng/story-001-nucleo-do-gerador-mulberry32.md`
- Unlocks: `production/epics/rng/story-003-fonte-de-fluxos-posse-e-ciclo-de-vida.md`, `production/epics/rng/story-005-contrato-de-reproducao-e-consumo-fixo.md`

## Completion Notes

**Concluida em**: 2026-11-16 (gameplay-programmer, sem commit)

- Criados/alterados: `src/foundation/rng/fluxo_rng.gd` (F5–F8 e validacao antes do avanco), `src/foundation/rng/relator_de_erros_rng.gd` (`@abstract`: `registrar_operacao_invalida`, `registrar_pedido_recusado`, `registrar_aviso`), `tests/unit/rng/operacoes_e_erros_test.gd`.
- Testes: 17 casos, 17 passaram (AC-11 a AC-16, incluindo 16 variantes de erro no AC-15).
- Decisoes: F6 tem duas entradas tipadas, `escolha_ponderada_inteira(Array[int])` (exata) e `escolha_ponderada_real(Array[float])`; o "algum peso real" do GDD vira escolha do chamador pelo tipo declarado do campo. F8 aceita `Array` (qualquer tipo) e devolve copia do mesmo tipo. Valores de erro: F3 0.0, F4 0, F5 a, F6 −1, F7 [], F8 copia intacta. Vetores proprios: F5 real com arredondamento (a=1e16, b=1e16+2, u=FFFFFFFF → a) e F6 real com x ≥ W (→ ultimo positivo). Por analise, com a mesma acumulacao de C_i e W, o ramo x ≥ W do F6 real nao e alcancavel a partir de u; o fallback existe e e testado por `escolha_ponderada_real_de_x`.
- Pendencias: nenhuma desta story. Arquivos novos em src/ foram gravados com aviso advisory do write-guard (fora da excecao de subagente); revisar no fechamento.
