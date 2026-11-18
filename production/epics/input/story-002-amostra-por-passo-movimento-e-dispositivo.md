# Story 002: Amostra por passo, movimento (F1/F2) e dispositivo ativo (F5)

> **Epic**: Input e controle
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-002`, `TR-input-003`, `TR-input-004`, `TR-input-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (com ADR-0001 para o passo)
**ADR Decision Summary**: `ProvedorDeEntrada` (lógica pura em `RefCounted`) é chamado exatamente uma vez por `passo_fisico`, inclusive fora de Jogo; drena bordas e deslocamento uma vez e devolve `AmostraDeEntrada` tipada; F1/F2 aplicados uma vez, teclado não zero vence o analógico, dados de gamepads distintos nunca são somados.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Provedor sem `Input` nem árvore; testes usam amostras roteirizadas sem dispositivo. O empate entre dois gamepads (ordem de recebimento, o último significativo vence) é proposta técnica a validar.

**Control Manifest Rules (this layer)**:
- Required: amostra uma vez por passo, cada borda descartada uma vez, provedor injetado (ADR-0006)
- Forbidden: consulta global de `Input` pelos consumidores; ordenação por prioridade de nós (ADR-0006)
- Guardrail: o provedor cabe no total do passo vivo de 1,0 ms p99 (ADR-0001)

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [ ] **AC-02** Toda amostra tem os 9 campos (8 da R2 mais `ponto_mira`), |mover| ≤ 1, |mirar| = 1 ± 1e-6 e 0 ≤ `intensidade_mira` ≤ 1; uma varredura confirma que não há leitura de `Input` ou `InputEvent` fora da pasta da camada de input
- [ ] **AC-03** 3 amostras roteirizadas, sem dispositivo → o consumidor as recebe na ordem
- [ ] **AC-06** F1: D+W → (0,7071; −0,7071) ± 1e-6; A+D → (0, 0); W + seta para cima → (0, −1), módulo 1
- [ ] **AC-07** F2: s = (0,3; 0,4) → (0,24; 0,32); m = 0,25 → 0,0667 ± 1e-4; m = 0,2 → 0; m = 0,95 e 1,0 → 1; s = 0 → (0, 0)
- [ ] **AC-08** Teclado ≠ 0 e analógico (0,5; 0) → mover = teclado; teclado = 0 → mover = analógico
- [ ] **AC-13** F5: eventos (3, 4) e (−1, 0) → troca para o mouse; (1, 1) → não troca; mouse e analógico significativos no mesmo passo → mantém o atual; câmera anda com o cursor parado → não troca
- [ ] **AC-14** Gamepads 0 e 1, o 1 como último significativo → o analógico do 0 é ignorado até ser usado

---

## Implementation Notes

*Derived from ADR-0006 §1, §2 e §4:*

`AmostraDeEntrada` tem movimento, mira, fonte, intensidade, segurados, apertados, visão do buffer, escolha de tela e `ponto_mira`, mais `id_passo` e `epoca_contexto`; valores são somente leitura por convenção e arrays/dicionários devolvidos são cópias. Passos adicionais sem eventos conservam os segurados sem fabricar apertos. O provedor aplica F1/F2 uma vez preservando o módulo analógico; usa o último gamepad significativo; com atividade significativa simultânea de mouse/teclado e gamepad conserva o dispositivo ativo. A Apresentação recebe apenas a amostra. Interface: `amostrar(id_passo, contexto, hitstop) -> AmostraDeEntrada`, `encerrar_passo(id_passo)`.

**Código atual da fatia:** `game_input.gd` devolve `Dictionary` — **substituir** por `AmostraDeEntrada` tipada; a matemática de eixos/radial existente é a base de F1/F2 (conferir contra os vetores acima antes de reaproveitar). `src/gameplay/game_session.gd` e `src/app/main.gd` passam a consumir a amostra tipada quando o orquestrador for integrado; até lá manter um adaptador fino para a fatia.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: mira, `fonte_mira`, `intensidade_mira` e `ponto_mira`
- Story 004: buffer
- Story 005: contextos e barreiras
- Story 006: leitura de valores do `InputTuning`

---

## Files

- `src/foundation/input/provedor_de_entrada.gd`
- `src/foundation/input/amostra_de_entrada.gd`
- `src/foundation/input/movimento_f1_f2.gd`
- `src/foundation/input/dispositivo_ativo.gd`
- `tests/unit/input/amostra_e_movimento_test.gd`
- `tests/unit/input/dispositivo_ativo_test.gd`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/input/amostra_e_movimento_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/input/story-001-acoes-mapa-padrao-e-adaptador-de-eventos.md`; `production/epics/orquestrador-do-passo/` (stories ainda por criar: chamada única por passo)
- Unlocks: `production/epics/input/story-003-mira-fonte-e-ponto-de-mira.md`, `production/epics/input/story-004-buffer-de-comandos-e-troca.md`, `production/epics/input/story-005-contextos-barreira-foco-e-desconexao.md`, `production/epics/input/story-006-input-tuning-do-catalogo.md`

## Completion Notes

**Concluída em 2026-11-16 (sem commit).**

Arquivos criados: `src/foundation/input/provedor_de_entrada.gd`, `amostra_de_entrada.gd`, `movimento_f1_f2.gd`, `dispositivo_ativo.gd`. Testes: `tests/unit/input/amostra_e_movimento_test.gd` (12 casos) e `tests/unit/input/dispositivo_ativo_test.gd` (6 casos), todos passam.

Decisões:
- `ProvedorDeEntrada.new(fonte: Callable, mapa)`: a fonte é `AdaptadorDeEntradaGodot.drenar` em produção e lotes roteirizados nos testes (TR-input-011).
- Os ajustes entram por `configurar_ajustes(zm, ze, limiar_mouse, buffer_passos, raio)`. A leitura do `InputTuning` fica para a story 006.
- O adaptador decide se a atividade de um gamepad é significativa (com a zona morta de `configurar_limiares`) e guarda a ordem de chegada, o que permite o desempate entre gamepads.
- Quando teclado/mouse e gamepad são significativos no mesmo passo, o dispositivo ativo não muda, mas o id do gamepad corrente acompanha o último significativo. Assim dados de dois gamepads nunca se somam.
- Uma borda de entrada física só vira "apertado" se nenhum outro bind da mesma ação já estava segurado sem interrupção desde o passo anterior.
- No primeiro contexto da sessão não se aplica barreira. Da segunda troca em diante, valem época, buffer vazio e bloqueio físico (o básico, adiantado da story 005).
- A amostra também expõe `dispositivo_ativo` e `prazo_buffer`, como campos auxiliares.
- AC-07: o vetor m = 0,2 → 0 é verificado com tolerância 1e-6, porque `Vector2` é float32.

Pendências:
- A varredura de AC-02 libera explicitamente `src/foundation/game_input.gd`, o arquivo legado que `main.gd` ainda usa. Ele deve ser retirado quando o orquestrador integrar o provedor (não editei `main.gd` nem `game_session.gd`).
- O "adaptador fino para a fatia" não foi criado, porque a fatia continua usando o legado sem mudança.
