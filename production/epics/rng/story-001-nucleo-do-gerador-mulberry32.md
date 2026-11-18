# Story 001: Núcleo do gerador mulberry32, derivação de fluxo e máscara u32

> **Epic**: RNG com seed
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-007`, `TR-rng-010` (máscara u32 na fronteira; a leitura de save fica com Persistência)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico
**ADR Decision Summary**: `FluxoRng` é lógica pura em `RefCounted`, estado uint32 no int de 64 bits do GDScript, `imul` em metades de 16 bits, derivação por F2. As funções aritméticas F1–F9 ficam separadas da posse de estado, para testar vetores do cânone.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Só aritmética inteira de 64 bits e `RefCounted`; nenhuma API pós-cutoff. O experimento `prototypes/rng-verificacao/` (33 checks) cobre F1, F2, F4 e o ramo inteiro de F6; é referência, não código a copiar.

**Control Manifest Rules (this layer)**:
- Required: RNG próprio em aritmética inteira de 64 bits; fluxos por finalidade com posse e autorização (ADR-0005)
- Forbidden: `RandomNumberGenerator` da engine, `randf`/`randi`/`shuffle`/`pick_random` na lógica (ADR-0005)
- Guardrail: referência ≤ 2 µs por passo e ≤ 5 µs por derivação (AC-33, advisory, medida na story 003)

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [ ] **AC-01** Estado `00000000`, 5 passos → estados `6D2B79F5 DA56F3EA 47826DDF B4ADE7D4 21D961C9` e saídas `4434B462 00159C37 39285B08 256D8104 77A2CBD4`
- [ ] **AC-02** Estado `3F9A07C2`, 5 passos → saídas `0865C80A D260910A B37DB9FA 91FD7BCE 7A515CDF`
- [ ] **AC-03** `imul(FFFFFFFF, FFFFFFFF)` = `00000001`
- [ ] **AC-04** F3: u = `4434B462` / `FFFFFFFF` / 0 → 0,266429208685 (±1e-12) / < 1 / 0
- [ ] **AC-05** F4, n = 100: u = 42949672 / 42949673 / `80000000` / `FFFFFFFF` → 0 / 1 / 50 / 99; a partir de `B0B08409`: F4(6) = 0 e F4(100) = 13 com estado final `1DDBFDFE`; n = 1 → 0 e consome 1
- [ ] **AC-06** `(u·n) >> 32` = `floor(u/2³²·n)` para uma lista fixa de u e n ∈ {1, 2, 3, 6, 7, 100, 2²¹}
- [ ] **AC-07** `fmix32(0 / 1 / FFFFFFFF)` = `00000000` / `514E28B7` / `81F16F39`
- [ ] **AC-08** (`3F9A07C2`, 4, 0, 0…4) → `0EC3245B 3043CE64 CFBE45BC B0B08409 83C51646`; (0, 1, 0, 0) → `E8A7E13D`
- [ ] **AC-09** Para as seeds 0, `3F9A07C2` e `FFFFFFFF`, as profundidades 0…1023 dão 1024 estados distintos
- [ ] **AC-10** As seeds −1 e 2³² + 5, passando pela fronteira, derivam o mesmo que `FFFFFFFF` e `00000005`

---

## Implementation Notes

*Derived from ADR-0005 (Decision: Algoritmo e estado):*

`FluxoRng` é `RefCounted` sem `SceneTree`. O estado é um uint32 guardado no `int` de 64 bits; máscaras e `imul` em metades de 16 bits preservam o resultado de 32 bits sem depender de overflow de multiplicação. As funções aritméticas (F1 avanço, F2 derivação, F3 real unitário, F4 inteiro 0..n−1) ficam em um módulo de funções puras separado da posse de estado. A chave de derivação aceita finalidade 1–9 (9 `pactos`, emenda), região 0–255 e índice da câmara 0–1023; chave inválida gera diagnóstico no relator injetado e nunca cria fluxo. A máscara uint32 aplica-se à seed numérica recebida na fronteira. Constantes e algoritmos fazem parte da versão do jogo: mudança de sequência exige atualizar a versão e os vetores.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: operações F5–F8, validação de argumentos e erros que não consomem
- Story 003: fonte de fluxos, posse, matriz dono × finalidade e ciclo de vida
- Story 004: texto da seed (F9) e entropia

---

## Files

- `src/foundation/rng/rng_aritmetica.gd` (funções puras F1–F4, `imul`, `fmix32`, máscara)
- `src/foundation/rng/fluxo_rng.gd`
- `tests/unit/rng/nucleo_do_gerador_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/rng/nucleo_do_gerador_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: None (a impressão e o manifesto do catálogo só entram na story 003)
- Unlocks: `production/epics/rng/story-002-operacoes-e-erros-que-nao-consomem.md`, `production/epics/rng/story-003-fonte-de-fluxos-posse-e-ciclo-de-vida.md`

## Completion Notes

**Concluida em**: 2026-11-16 (gameplay-programmer, sem commit)

- Criados: `src/foundation/rng/rng_aritmetica.gd` (F1–F6 como funcoes puras de u, `imul`, `fmix32`, `mix`, `derivar`, `mascarar_u32`, `chave_valida`), `src/foundation/rng/fluxo_rng.gd`, `tests/unit/rng/nucleo_do_gerador_test.gd`, dublê `tests/unit/rng/relator_gravador_rng.gd`.
- Testes: 13 casos, 13 passaram (AC-01 a AC-10). Rodado com gdUnit4 headless, sem erro de parse.
- Decisoes: F1 separado em `proximo_estado` + `saida_do_estado` para o teste ler estado e saida; a chave invalida e recusada pela fonte (story 003), `chave_valida` fica aqui. Constantes do algoritmo sao `const` (parte da versao do jogo, nao tuning).
- Pendencias: nenhuma desta story. Arquivos novos em src/ foram gravados com aviso advisory do write-guard (fora da excecao de subagente); revisar no fechamento.
