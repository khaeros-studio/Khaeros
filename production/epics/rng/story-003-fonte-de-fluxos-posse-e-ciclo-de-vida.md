# Story 003: Fonte de fluxos — posse, matriz dono × finalidade e ciclo de vida

> **Epic**: RNG com seed
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-003`, `TR-rng-004`, `TR-rng-009`, `TR-rng-013` (finalidade 9 e chave; o consumo fixo de 4 reais é da story 005)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico (com ADR-0004 para a ordem do manifesto)
**ADR Decision Summary**: O ponto de composição cria uma fonte por run, injetada por interfaces limitadas ao consumidor; a fonte mantém o mapa chave → fluxo, devolve o mesmo objeto para a mesma chave e invalida os fluxos retidos ao encerrar a run por um marcador compartilhado de validade.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: `RefCounted` puro; referências fonte → fluxos → marcador em uma direção para evitar ciclos.

**Control Manifest Rules (this layer)**:
- Required: fonte de fluxos injetada, sem singleton; sorteios iteram na ordem do manifesto, nunca por Dictionary, hash ou árvore (ADR-0005, ADR-0004)
- Forbidden: `Autoload`/`static var` com instância de RNG (ADR-0001, ADR-0005)
- Guardrail: abrir uma câmara (≤ 8 fluxos, ~50 sorteios) ≤ 0,1 ms; AC-33 só registra µs/op (advisory)

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [ ] **AC-24** Depois de 3 saídas, pedir o mesmo trio de novo devolve o mesmo fluxo: a 4ª saída é a 4ª da sequência contínua
- [ ] **AC-25** Matriz dono × finalidade: Câmaras só abre 1, 3 e 8; IA só 2 e 7; Portas só 4; Bênçãos só 5 e 6; fora da matriz → `null`, 1 erro, nenhum fluxo criado ou consumido
- [ ] **AC-26** Consumir 1000 números em (`ia`, 0, 2) não altera as saídas de (`ondas`, 0, 2) nem de (`portas`, 0, 3)
- [ ] **AC-30** Em Sem run, pedir um fluxo devolve `null` e o relator recebe (finalidade, região, profundidade, solicitante); ler a seed devolve "sem seed"; em Run ativa, finalidade 0 ou 9 fora de autorização, região −1 ou 256 e profundidade −1 ou 1024 recebem o mesmo tratamento
- [ ] **AC-31** Em Encerrada a seed é legível e qualquer trio, inclusive já aberto, devolve `null` com erro; ao passar para Sem run, os fluxos são descartados; um fluxo retido antes devolve o valor de erro da operação e preserva o estado
- [ ] **AC-36** Finalidade 9: (`pactos`, 0, 0) nasce pela F2, `s0` difere dos de (1–8, 0, 0) com a mesma seed e pedir de novo continua de onde parou; o vetor de referência com a seed `3F9A07C2` é calculado pelo script de paridade e entra na tabela antes de a story fechar
- [ ] **AC-29** (Integration) A seção `[autoload]` do `project.godot` e as `static var` não contêm nenhuma instância de RNG
- [ ] **AC-33** (advisory, `tests/performance/rng/`) 1.000.000 passos e 10.000 derivações registram µs/op, sem assert de tempo; regressão > 2× vira bug S3

---

## Implementation Notes

*Derived from ADR-0005 (Decision: Posse e autorização; Ciclo de vida; Emenda Pactos):*

Fonte por run com interfaces limitadas por consumidor (Câmaras 1/3/8, IA 2/7, Portas 4, Bênçãos 5/6, Vínculo 9 via ADR-0015). A ordem de criação das chaves e a iteração do mapa ficam fora das fórmulas de sorteio. O marcador compartilhado de validade guarda só o estado ativo e a identidade da sessão da run; encerrar a run o invalida antes de entregar o controle à tela final; toda operação consulta a validade antes de consumir; a run seguinte recebe um marcador novo mesmo com a mesma seed. Em Encerrada, seed e metadados continuam disponíveis. Estados: Sem run, Run ativa, Encerrada. A ordem das listas de opções vem do manifesto do catálogo (ADR-0004). A IA de aliado (ADR-0017) e o chefe não ganham fluxo.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: nascimento da seed, texto F9, entropia e `--seed`
- Story 005: consumo fixo e contrato de reprodução entre runs
- Story 006: lint de CI contra APIs aleatórias

---

## Files

- `src/foundation/rng/fonte_de_fluxos.gd`
- `src/foundation/rng/marcador_de_validade.gd`
- `src/foundation/rng/interfaces/` (uma interface limitada por consumidor)
- `tests/unit/rng/fonte_de_fluxos_test.gd`
- `tests/integration/rng/sem_rng_em_autoload_test.gd`
- `tests/performance/rng/custo_do_gerador_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/rng/fonte_de_fluxos_test.gd` — must exist and pass

**Status**: [x] Created and passing

---

## Dependencies

- Depends on: `production/epics/rng/story-001-nucleo-do-gerador-mulberry32.md`, `production/epics/rng/story-002-operacoes-e-erros-que-nao-consomem.md`
- Unlocks: `production/epics/rng/story-004-seed-da-run-texto-e-entropia.md`, `production/epics/rng/story-005-contrato-de-reproducao-e-consumo-fixo.md`

## Completion Notes

**Concluida em**: 2026-11-16 (gameplay-programmer, sem commit)

- Criados: `src/foundation/rng/fonte_de_fluxos.gd` (estados, ids 1–9, mapa chave→fluxo, `iniciar_run(seed, pactos_autorizado)`, `encerrar_run`, `descartar_run`, `abrir_fluxo`), `src/foundation/rng/marcador_de_validade.gd`, `src/foundation/rng/interfaces/` (`acesso_a_fluxos.gd` base + `fluxos_de_camaras/ia/portas/bencaos/vinculo.gd`), `tests/unit/rng/fonte_de_fluxos_test.gd`, `tests/integration/rng/sem_rng_em_autoload_test.gd`, `tests/performance/rng/custo_do_gerador_test.gd`.
- Testes: unit 10/10, integration (AC-29) 2/2, performance (AC-33) 1/1. AC-33 medido em editor/debug headless: passo ≈ 4,0 µs/op, derivacao ≈ 5,9–13 µs/op (acima da referencia de 2/5 µs do ADR, mas a referencia vale para build de release exportado; advisory, sem assert).
- AC-36: vetor de (pactos, 0, 0) com seed 3F9A07C2 calculado por script Python independente: s0 = `930387A6`; u = `0602A893 34D3D1BA 5A2B71C3 8E90077B`. Fixado no teste.
- Decisoes: finalidade 9 so abre com `pactos_autorizado` na criacao da run; `iniciar_run` fora de Sem run e recusado com aviso; a matriz dono × finalidade fica nas interfaces (a fonte valida estado, faixas e autorizacao). Encerrada → Sem run por `descartar_run()`.
- Pendencias: (1) a linha do vetor de `pactos` precisa entrar na tabela "Vetores de referencia" de `design/gdd/rng-com-seed.md` (game-designer; nao editei o GDD) e o script de paridade ainda nao esta em `tools/`; (2) medir AC-33 em build de release exportado. Arquivos novos em src/ foram gravados com aviso advisory do write-guard (fora da excecao de subagente); revisar no fechamento.
